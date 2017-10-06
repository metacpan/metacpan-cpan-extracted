package Dist::Zilla::PluginBundle::Author::WATERKIP;
use Moose;

# ABSTRACT: An plugin bundle for all distributions by WATERKIP
# KEYWORDS: author bundle distribution tool

use Moose::Util::TypeConstraints qw(enum subtype where);
use List::Util qw(uniq any first);
use namespace::autoclean;

our $VERSION = '1.5';

with
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
    'Dist::Zilla::Role::PluginBundle::Config::Slicer';

has server => (
    is => 'ro', isa => enum([qw(github bitbucket gitlab none)]),
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{server} // 'gitlab' },
);

has airplane => (
    is => 'ro', isa => 'Bool',
    init_arg => undef,
    lazy => 1,
    default => sub { $ENV{DZIL_AIRPLANE} || $_[0]->payload->{airplane} // 0 },
);

has license => (
    is => 'ro', isa => 'Str',
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{license} // 'LICENSE' },
);


has copy_file_from_release => (
    isa => 'ArrayRef[Str]',
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{copy_file_from_release} // [] },
    traits => ['Array'],
    handles => { copy_files_from_release => 'elements' },
);

has debug => (
    is => 'ro', isa => 'Bool',
    init_arg => undef,
    lazy => 1,
    default => sub { $ENV{DZIL_AUTHOR_DEBUG} // $_[0]->payload->{debug} // 0 },
);

has upload_to => (
    is => 'ro', isa => enum([qw(cpan pause stratopan local)]),
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{upload_to} // 'cpan' },
);

around copy_files_from_release => sub {
    my $orig = shift; my $self = shift;
    sort(uniq(
            $self->$orig(@_),
            qw(LICENCE LICENSE CONTRIBUTING ppport.h INSTALL
            Makefile.PL cpanfile README Build.PL)
    ));
};

has authority => (
    is => 'ro', isa => 'Str',
    init_arg => undef,
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->payload->{authority} // 'cpan:WATERKIP';
    },
);

has fake_release => (
    is => 'ro', isa => 'Bool',
    init_arg => undef,
    lazy => 1,
    default => sub { $ENV{FAKE_RELEASE} // $_[0]->payload->{fake_release} // 0 },
);

has changes_version_columns => (
    is       => 'ro',
    isa      => subtype('Int', where { $_ > 0 && $_ < 20 }),
    init_arg => undef,
    lazy     => 1,
    default => sub { $_[0]->payload->{changes_version_columns} // 10 },
);

my @network_plugins = qw(
    PromptIfStale
    Test::Pod::LinkCheck
    Test::Pod::No404s
    Git::Remote::Check
    CheckPrereqsIndexed
    CheckIssues
    UploadToCPAN
    UploadToStratopan
    Git::Push
);
my %network_plugins;
@network_plugins{ map { Dist::Zilla::Util->expand_config_package_name($_) } @network_plugins } = () x @network_plugins;

sub _warn_me {
    my $msg = shift;
    warn(sprintf("[\@Author::WATERKIP]  %s\n", $msg));
}

sub commit_files_after_release {
    grep { -e } sort(uniq('README.md', 'README.pod', 'Changes', shift->copy_files_from_release));
}

my %removed;

sub release_option {
    my $self = shift;
    if ($self->fake_release) {
        _warn_me("Fake release has been set");
        return 'FakeRelease';
    }
    if ($self->upload_to eq 'stratopan') {
        _warn_me("Stratopan release has been set");
        my $prefix = 'stratopan';
        return [
            'UploadToStratopan' => {
                repo    => $self->payload->{"$prefix.repo"},
                stack   => $self->payload->{"$prefix.stack"},
                recurse => $self->payload->{"$prefix.recurse"},
            }
        ],
    }
    return 'UploadToCPAN';
}

sub configure {
    my $self = shift;

    if ($self->debug) {
        use Data::Dumper;
        _warn_me(
            Dumper {
                payload => $self->payload,
            }
        );
    }

    if (!-d '.git' and -f 'META.json' and !exists $removed{'Git::GatherDir'}) {
        _warn_me(
            '.git is missing and META.json is present -- this looks like a CPAN download rather than a git repository. You should probably run '
                . ( -f 'Build.PL' ? 'perl Build.PL; ./Build' : 'perl Makefile.PL; make') . ' instead of using dzil commands!',
        );
    }

    my @plugins = (

        [
            'Git::GatherDir' => {
                do {
                    my @filenames
                        = grep { -e } $self->copy_files_from_release;
                    @filenames ? (exclude_filename => \@filenames) : ();
                },
            },
        ],

        qw(PruneCruft ManifestSkip MetaYAML MetaJSON),

        [ 'License' => { filename => $self->license } ],

        qw(Readme ExecDir ShareDir MakeMaker Manifest
           TestRelease PodWeaver),

        [ 'AutoPrereqs' => { skip => [qw(^perl$ ^namespace::autoclean$)]}],
        [ 'Prereqs::AuthorDeps' => { ':version' => '0.006' } ],
        [ 'MinimumPerl'         => { ':version' => '1.006', configure_finder => ':NoFiles' } ],
        ['CPANFile'],
        #['Test::CPAN::Changes'],
        ['Repository'],
        ['ConfirmRelease'],

#        [ 'PrereqsClean'],

        $self->release_option,

        # Perhaps do copy files from build first?
        # [ 'CopyFilesFromBuild' => { filename => [ $self->copy_files_from_release ] } ],
        [ 'CopyFilesFromRelease' => { filename => [ $self->copy_files_from_release ] } ],
        # Don't generate a change log from git just yet, figure out
        # first what our workflow will be
        #['ChangelogFromGit' => { include_message => '^release' } ],


    );

    if ($self->airplane) {
        _warn_me("Building in airplane mode, skipping network required modules");
        @plugins = grep {
            my $plugin = Dist::Zilla::Util->expand_config_package_name(
                !ref($_) ? $_ : ref eq 'ARRAY' ? $_->[0] : die 'wtf'
            );
            not exists $network_plugins{$plugin}
        } @plugins;

        # allow our uncommitted dist.ini edit which sets 'airplane = 1'
        #push @{( first { ref eq 'ARRAY' && $_->[0] eq 'Git::Check' } @plugins )->[-1]{allow_dirty}}, 'dist.ini';

        # halt release after pre-release checks, but before ConfirmRelease
        push @plugins, 'BlockRelease';
    }

    # plugins to do with calculating, munging, incrementing versions
    $self->add_bundle('@Git::VersionManager' => {
        'RewriteVersion::Transitional.global' => 1,
        'RewriteVersion::Transitional.fallback_version_provider' => 'Git::NextVersion',
        'RewriteVersion::Transitional.version_regexp' => '^v([\d._]+)(-TRIAL)?$',

        # for first Git::Commit
        commit_files_after_release => [ $self->commit_files_after_release ],
        # because of [Git::Check], only files copied from the release would be added -- there is nothing else
        # hanging around in the current directory
        'release snapshot.add_files_in' => ['.'],
        'release snapshot.commit_msg' => '%N-%v%t%n%n%c',

        'Git::Tag.tag_message' => 'v%v%t',

        'BumpVersionAfterRelease::Transitional.global' => 1,

        'NextRelease.:version' => '5.033',
        'NextRelease.time_zone' => 'UTC',
        'NextRelease.format' => '%-' . ($self->changes_version_columns - 2) . 'v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T',
    });
    $self->add_bundle('@TestingMania');
    $self->add_plugins(@plugins);

}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::WATERKIP - An plugin bundle for all distributions by WATERKIP

=head1 VERSION

version 1.5

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::WATERKIP]

=head1 METHODS

=head2 configure

Configure the author plugin

=head2 commit_files_after_release

Commit files after a release

=head1 SEE ALSO

I took inspiration from L<Dist::Zilla::PluginBundle::Author::ETHER>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Wesley Schwengle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
