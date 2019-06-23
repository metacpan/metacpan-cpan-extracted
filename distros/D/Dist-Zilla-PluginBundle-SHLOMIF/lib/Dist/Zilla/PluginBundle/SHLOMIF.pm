package Dist::Zilla::PluginBundle::SHLOMIF;
$Dist::Zilla::PluginBundle::SHLOMIF::VERSION = '0.000009';
use 5.014;

use Moose;
# ABSTRACT: Dist::Zilla plugins for me

use List::MoreUtils qw(any);

use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';


has dist => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has authority => (
    is      => 'ro',
    isa     => 'Str',
    default => 'cpan:SHLOMIF',
);

has github_user => (
    is      => 'ro',
    isa     => 'Str',
    default => 'shlomif',
);

has github_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { lc shift->dist },
);

has repository => (
    is  => 'ro',
    isa => 'Str',
    default => 'github',
);

for my $attr (qw(repository_type repository_url repository_web)) {
    has $attr => (
        is      => 'ro',
        isa     => 'Maybe[Str]',
        lazy    => 1,
        default => sub {
            my $self = shift;
            my $data = $self->_repository_data;
            return unless $data;
            return $data->{$attr};
        },
    );
}

sub _repository_data {
    my $self = shift;

    my $host = $self->repository;
    return unless defined $host;

    die "Unknown repository host $host"
        unless exists $self->_repository_host_map->{$host};

    return $self->_repository_host_map->{$host};
}

has _repository_host_map => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[Str]]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {
            'github' => {
                repository_type => 'git',
                repository_url  => sprintf('git://github.com/%s/%s.git', $self->github_user, $self->github_name),
                repository_web  => sprintf('https://github.com/%s/%s', $self->github_user, $self->github_name),
            },
        }
    },
);

has bugtracker => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->repository eq 'github' ? 'github' : 'rt' },
);

for my $attr (qw(bugtracker_web bugtracker_mailto)) {
    has $attr => (
        is      => 'ro',
        isa     => 'Maybe[Str]',
        lazy    => 1,
        default => sub {
            my $self = shift;
            my $data = $self->_bugtracker_data;
            return unless $data;
            return $data->{$attr};
        },
    );
}

sub _bugtracker_data {
    my $self = shift;

    my $host = $self->bugtracker;
    return unless defined $host;

    die "Unknown bugtracker host $host"
        unless exists $self->_bugtracker_host_map->{$host};

    return $self->_bugtracker_host_map->{$host};
}

has _bugtracker_host_map => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[Str]]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {
            'github' => {
                bugtracker_web  => sprintf('https://github.com/%s/%s/issues', $self->github_user, $self->github_name),
            },
            'rt' => {
                bugtracker_web    => sprintf('http://rt.cpan.org/Public/Dist/Display.html?Name=%s', $self->dist),
                bugtracker_mailto => sprintf('bug-%s@rt.cpan.org', lc $self->dist),
            },
        }
    },
);

has homepage => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { sprintf('http://metacpan.org/release/%s', shift->dist) },
);

has awesome => (
    is  => 'ro',
    isa => 'Str',
);

has dynamic_config => (
    is  => 'ro',
    isa => 'Str',
);

has is_task => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { shift->dist =~ /^Task-/ ? 1 : 0 },
);

has is_test_dist => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 1 if $ENV{DZIL_FAKE_RELEASE};
        return $self->dist =~ /^Foo-/ ? 1 : 0
    },
);

has done_testing => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has _plugins => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [
            qw(
                AutoPrereqs
                ExecDir
                GatherDir
                License
                ManifestSkip
                MetaYAML
                PruneCruft
                Readme
                RunExtraTests
                ShareDir
            ),
            ($self->awesome ? $self->awesome : 'MakeMaker'),
            qw(
                CheckChangesHasContent
                ConfirmRelease
                Manifest
                MetaConfig
                MetaJSON
                MetaProvides::Package
                MetaResources
                ModuleBuild
                PkgVersion
                PodCoverageTests
                PodSyntaxTests
                Test::Compile
                Test::CPAN::Changes
                Test::EOL
                Test::NoTabs
                Test::TrailingSpace
                TestRelease
            ),
            ($self->is_task      ? 'TaskWeaver'  : 'PodWeaver'),
            ($self->is_test_dist ? 'FakeRelease' : 'UploadToCPAN'),
        ]
    },
);

has plugin_options => (
    is       => 'ro',
    isa      => 'HashRef[HashRef[Str]]',
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my %opts = (
            'Authority'          => { authority => $self->authority },
        );

        for my $metaresource (qw(repository.type repository.url repository.web bugtracker.web bugtracker.mailto homepage)) {
            (my $method = $metaresource) =~ s/\./_/g;
            my $value = $self->$method;
            if (!$value) {
                warn "*** resources.$metaresource is not configured! This needs to be fixed! ***"
                    unless $metaresource eq 'bugtracker.mailto';
                next;
            }
            $opts{MetaResources}{$metaresource} = $value;
        }
        delete $opts{MetaResources}{'repository.type'}
            unless exists $opts{MetaResources}{'repository.url'};

        for my $option (keys %{ $self->payload }) {
            next unless $option =~ /^([A-Z][^_]*)_(.+)$/;
            my ($plugin, $plugin_option) = ($1, $2);
            $opts{$plugin} ||= {};
            $opts{$plugin}->{$plugin_option} = $self->payload->{$option};
        }

        return \%opts;
    },
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my $args = $class->$orig(@_);
    return { %{ $args->{payload} }, %{ $args } };
};

sub configure {
    my $self = shift;

    $self->add_plugins(
        [ 'Prereqs' => 'TestMoreDoneTesting' => {
            -phase       => 'test',
            -type        => 'requires',
            'Test::More' => '0.88',
        } ]
    ) if $self->done_testing;
    $self->add_plugins(
        map { [ $_ => ($self->plugin_options->{$_} || {}) ] }
            @{ $self->_plugins },
    );
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::SHLOMIF - Dist::Zilla plugins for me

=head1 VERSION

version 0.000009

=head1 SYNOPSIS

  # dist.ini
  [@SHLOMIF]
  dist = Dist-Zilla-PluginBundle-SHLOMIF
  repository = github

=head1 DESCRIPTION

Shlomi Fish’s plugin bundle (originally derived/forked/based-on
L<https://github.com/doy/dist-zilla-pluginbundle-doy> - thanks). Roughly
equivalent to (FILL IN/update).

    [Prereqs / TestMoreDoneTesting]
    -phase = test
    -type = requires
    Test::More = 0.88

    [GatherDir]
    [PruneCruft]
    [ManifestSkip]
    [MetaYAML]
    [License]
    [Readme]
    [RunExtraTests]
    [ExecDir]
    [ShareDir]
    [MakeMaker]
    [Manifest]

    [TestRelease]
    [ConfirmRelease]

    [MetaConfig]
    [MetaJSON]

    [NextRelease]
    format = %-5v %{yyyy-MM-dd}d
    [CheckChangesHasContent]

    [PkgVersion]
    [Authority]
    authority = cpan:SHLOMIF

    [PodCoverageTests]
    [PodSyntaxTests]
    [Test::NoTabs]
    [EOLTests]
    [Test::Compile]

    [MetaResources]
    ; autoconfigured, based on the value of 'repository'

    [Git::Check]
    allow_dirty =
    [Git::Commit]
    commit_msg = changelog
    [Git::Tag]
    tag_format = %v
    tag_message =
    [Git::NextVersion]
    version_regexp = ^(\d+\.\d+)$
    first_version = 0.01

    [PodWeaver]

    [UploadToCPAN]

    [ContributorsFromGit]
    [MetaProvides::Package]

=head1 NAME

Dist::Zilla::PluginBundle::SHLOMIF - dzil plugins for SHLOMIF (Shlomi Fish)

=head1 VERSION

version 0.000009

=head1 SEE ALSO

L<Dist::Zilla>

L<Task::BeLike::DOY>

L<Dist::Zilla::PluginBundle::DOY>

=for Pod::Coverage   configure

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
