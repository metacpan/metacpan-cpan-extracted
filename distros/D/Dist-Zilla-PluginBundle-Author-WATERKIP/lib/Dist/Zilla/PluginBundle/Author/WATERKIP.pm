package Dist::Zilla::PluginBundle::Author::WATERKIP;
use Moose;
our $VERSION = '1.0';

# ABSTRACT: An plugin bundle for all distributions by WATERKIP
# KEYWORDS: author bundle distribution tool

use Moose::Util::TypeConstraints qw(enum);
use List::Util qw(uniq any first);
use namespace::autoclean;

# Have multi value args
sub mvp_multivalue_args {
    return qw(copy_file_from_release);
}

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

around copy_files_from_release => sub {
    my $orig = shift; my $self = shift;
    sort(uniq(
            $self->$orig(@_),
            qw(LICENCE LICENSE CONTRIBUTING Changes CHANGES ppport.h INSTALL Makefile.PL cpanfile README README.md)
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
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    lazy     => 1,
    default  => sub {
            $ENV{FAKE_RELEASE}
            || $_[0]->payload->{fake_release} // 0;
    },
);

has test_release => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    lazy     => 1,
    # Currently all our releases are test releases
    default => sub { $_[0]->payload->{test_release} // 1 },
);

my @network_plugins = qw(
    PromptIfStale
    Test::Pod::LinkCheck
    Test::Pod::No404s
    Git::Remote::Check
    CheckPrereqsIndexed
    CheckIssues
    UploadToCPAN
    Git::Push
);
my %network_plugins;
@network_plugins{ map { Dist::Zilla::Util->expand_config_package_name($_) } @network_plugins } = () x @network_plugins;

sub _warn_me {
    my $msg = shift;
    warn(sprintf("[\@Author::WATERKIP]  %s\n", $msg));
}

my %removed;

sub configure {
    my $self = shift;


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
                    my @filenames = $self->copy_files_from_release;
                    @filenames ? (exclude_filename => \@filenames) : ();
                },
            },
        ],

        qw(MetaYAML MetaJSON Readme ManifestSkip Manifest),

        $self->test_release ? () :
        [
            'Git::Check' => {
                allow_dirty     => [$self->copy_files_from_release],
            }
        ],


        [ 'License' => { filename => $self->license } ],

        ['PruneCruft'],
        ['ExtraTests'],
        ['ExecDir'],
        ['ShareDir'],
        ['MakeMaker'],
        ['ChangelogFromGit'],
        #['TestRelease'],
        ['CPANFile'],

        $self->fake_release ? do { _warn_me('FAKE_RELEASE set - not uploading to CPAN'); 'FakeRelease' }
           : 'UploadToCPAN',

        [ 'CopyFilesFromRelease' => { filename => [ $self->copy_files_from_release ] } ],

        [ 'PodWeaver'],
        [ 'AutoPrereqs'],
        [ 'Prereqs::AuthorDeps' => { ':version' => '0.006' } ],
        [ 'MinimumPerl'         => { ':version' => '1.006', configure_finder => ':NoFiles' } ],

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

    $self->add_plugins(@plugins);

}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::WATERKIP - An plugin bundle for all distributions by WATERKIP

=head1 VERSION

version 1.0

=head1 AUTHOR

Wesley Schwengle <wesley@schwengle.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Wesley Schwengle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
