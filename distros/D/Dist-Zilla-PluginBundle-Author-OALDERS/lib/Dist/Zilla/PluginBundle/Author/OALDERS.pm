package Dist::Zilla::PluginBundle::Author::OALDERS;

use Moose;
use namespace::autoclean;

our $VERSION = '0.000018';

use feature qw( say );

use List::AllUtils qw( first );
use Pod::Elemental::Transformer::List;
use Types::Path::Tiny qw( Path );
use Types::Standard qw( ArrayRef Maybe Str );

with(
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover',
    'Dist::Zilla::Role::PluginBundle::Config::Slicer',    # needs to come last
);

has stopwords => (
    traits    => ['Array'],
    is        => 'ro',
    isa       => ArrayRef [Str],
    predicate => '_has_stopwords',
    required  => 0,
);

has stopwords_file => (
    is      => 'ro',
    isa     => Maybe [Path],
    coerce  => 1,
    default => sub {
        first { -e } ( '.stopwords', 'stopwords' );
    },
);

sub configure {
    my $self = shift;

    my $readme          = 'README.md';
    my @copy_from_build = (
        'cpanfile', 'LICENSE', 'Makefile.PL', 'META.json', $readme,
    );
    my @copy_from_release = ('Install');

    my @allow_dirty
        = ( 'dist.ini', 'Changes', @copy_from_build, @copy_from_release );

    my @plugins = (
        [
            'PromptIfStale' => 'stale modules, build' => {
                phase  => 'build',
                module => [ $self->meta->name ]
            }
        ],
        [
            'PromptIfStale' => 'stale modules, release' => {
                phase             => 'release',
                check_all_plugins => 1,
                check_all_prereqs => 1,
            }
        ],

        'MAXMIND::TidyAll',

        'AutoPrereqs',
        'CheckChangesHasContent',
        'MakeMaker',    # needs to precede InstallGuide
        'CPANFile',
        'ContributorsFile',
        'MetaJSON',
        'MetaYAML',
        'Manifest',
        [ 'MetaNoIndex' => { directory => [ 'examples', 't', 'xt' ] } ],
        'MetaConfig',
        'MetaResources',
        'License',
        'InstallGuide',

        'Prereqs',

        'ExecDir',

        [ 'Test::PodSpelling' => { stopwords => $self->_all_stopwords } ],
        'PodCoverageTests',
        'Test::CPAN::Changes',
        'TestRelease',
        'Test::ReportPrereqs',
        'Test::Synopsis',
        'Test::TidyAll',

        'RunExtraTests',

        'MinimumPerl',
        'PodWeaver',
        'PruneCruft',

        [ 'CopyFilesFromBuild' => { copy => \@copy_from_build } ],

        [ 'GithubMeta' => { issues => 1 } ],
        [
            'Git::GatherDir' => {
                exclude_filename => [ @copy_from_build, @copy_from_release ]
            }
        ],
        [ 'CopyFilesFromRelease' => { filename    => [@copy_from_release] } ],
        [ 'Git::Check'           => { allow_dirty => \@allow_dirty } ],
        'Git::Contributors',

        [
            'ReadmeAnyFromPod' => 'ReadmeMdInBuild' => {
                filename => $readme,
                location => 'build',
                type     => 'markdown',
            }
        ],
        'ShareDir',
        'TravisCI::StatusBadge',
        'ConfirmRelease',
        'UploadToCPAN',
    );

    $self->add_plugins($_) for @plugins;
    $self->add_bundle(
        '@Git::VersionManager' => {
            commit_files_after_release => \@allow_dirty,
            'RewriteVersion::Transitional.fallback_version_provider' =>
                'Git::NextVersion',
        }
    );

    $self->add_plugins('Git::Push');
}

sub _all_stopwords {
    my $self = shift;

    my @stopwords = $self->_default_stopwords;
    push @stopwords, @{ $self->stopwords } if $self->_has_stopwords;

    if ( $self->stopwords_file ) {
        push @stopwords, $self->stopwords_file->lines_utf8( { chomp => 1 } );
    }

    return \@stopwords;
}

sub _default_stopwords {
    qw(
        Alders
        Alders'
    );
}

__PACKAGE__->meta->make_immutable;
1;

#ABSTRACT: A plugin bundle for distributions built by OALDERS

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::OALDERS - A plugin bundle for distributions built by OALDERS

=head1 VERSION

version 0.000018

=head2 configure

No docs for the time being, but you can see the bundled plugin by checking
c<configure()> in the module source.

=head1 SEE ALSO

I used L<https://metacpan.org/pod/Dist::Zilla::PluginBundle::RJBS> and
L<https://metacpan.org/pod/Dist::Zilla::PluginBundle::Author::DBOOK> as
templates to get my own bundle started.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
