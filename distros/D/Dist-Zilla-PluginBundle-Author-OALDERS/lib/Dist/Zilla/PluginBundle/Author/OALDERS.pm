package Dist::Zilla::PluginBundle::Author::OALDERS;
$Dist::Zilla::PluginBundle::Author::OALDERS::VERSION = '0.000011';
use Moose;
use namespace::autoclean;

use feature qw( say );

use Dist::Zilla::Plugin::AutoPrereqs;
use Dist::Zilla::Plugin::CPANFile;
use Dist::Zilla::Plugin::CheckChangesHasContent;
use Dist::Zilla::Plugin::ConfirmRelease;
use Dist::Zilla::Plugin::ContributorsFile;
use Dist::Zilla::Plugin::CopyFilesFromBuild;
use Dist::Zilla::Plugin::ExecDir;
use Dist::Zilla::Plugin::Git::Check;
use Dist::Zilla::Plugin::Git::Commit;
use Dist::Zilla::Plugin::Git::Contributors;
use Dist::Zilla::Plugin::Git::GatherDir;
use Dist::Zilla::Plugin::Git::Push;
use Dist::Zilla::Plugin::Git::Tag;
use Dist::Zilla::Plugin::GithubMeta;
use Dist::Zilla::Plugin::InstallGuide;
use Dist::Zilla::Plugin::License;
use Dist::Zilla::Plugin::MAXMIND::TidyAll;
use Dist::Zilla::Plugin::MakeMaker;
use Dist::Zilla::Plugin::Manifest;
use Dist::Zilla::Plugin::ManifestSkip;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::MetaConfig;
use Dist::Zilla::Plugin::MetaNoIndex;
use Dist::Zilla::Plugin::MetaResources;
use Dist::Zilla::Plugin::MetaYAML;
use Dist::Zilla::Plugin::MinimumPerl;
use Dist::Zilla::Plugin::PkgVersion;
use Dist::Zilla::Plugin::PodCoverageTests;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Plugin::Prereqs;
use Dist::Zilla::Plugin::PromptIfStale;
use Dist::Zilla::Plugin::PruneCruft;
use Dist::Zilla::Plugin::ReadmeAnyFromPod;
use Dist::Zilla::Plugin::RunExtraTests;
use Dist::Zilla::Plugin::ShareDir;
use Dist::Zilla::Plugin::Test::CPAN::Changes;
use Dist::Zilla::Plugin::Test::PodSpelling;
use Dist::Zilla::Plugin::TestRelease;
use Dist::Zilla::Plugin::Test::ReportPrereqs;
use Dist::Zilla::Plugin::Test::Synopsis;
use Dist::Zilla::Plugin::Test::TidyAll;
use Dist::Zilla::Plugin::TravisCI::StatusBadge;
use Dist::Zilla::Plugin::UploadToCPAN;
use List::AllUtils qw( first );
use Pod::Elemental::Transformer::List;
use Types::Path::Tiny qw( Path );
use Types::Standard qw( ArrayRef Maybe Str );

with(
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover',
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

    my $readme = 'README.md';
    my @copy   = (
        'cpanfile', 'Install', 'LICENSE', 'Makefile.PL', 'META.json',
        $readme
    );

    my @allow_dirty = ( 'dist.ini', 'Changes', @copy );

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

        'AutoPrereqs',
        'CheckChangesHasContent',
        'CPANFile',
        'ConfirmRelease',
        'ContributorsFile',
        [ 'CopyFilesFromBuild' => { copy => \@copy } ],
        'ExecDir',

        'RunExtraTests',

        [
            'NextRelease' => {
                time_zone => 'UTC',
                format =>
                    q{%-8v  %{yyyy-MM-dd HH:mm:ss'Z'}d%{ (TRIAL RELEASE)}T},
            }
        ],

        [ 'GithubMeta'     => { issues           => 1 } ],
        [ 'Git::GatherDir' => { exclude_filename => \@copy } ],
        [ 'Git::Check'     => { allow_dirty      => \@allow_dirty } ],
        [
            'Git::Commit' => 'commit generated files' => {
                allow_dirty => \@allow_dirty,
            },
        ],
        'Git::Contributors',
        'Git::Tag',
        'Git::Push',
        'InstallGuide',
        'License',
        'MakeMaker',
        'Manifest',
        'ManifestSkip',
        'MAXMIND::TidyAll',
        'MetaJSON',
        [ 'MetaNoIndex' => { directory => [ 'examples', 't', 'xt' ] } ],
        'MetaResources',
        'MetaYAML',
        'MetaConfig',
        'MinimumPerl',
        'PkgVersion',
        'PodCoverageTests',
        'PodWeaver',
        'Prereqs',
        'PruneCruft',
        [
            'ReadmeAnyFromPod' => 'ReadmeMdInBuild' => {
                filename => $readme,
                location => 'build',
                type     => 'markdown',
            }
        ],
        'ShareDir',
        'Test::CPAN::Changes',
        [ 'Test::PodSpelling' => { stopwords => $self->_all_stopwords } ],
        'TestRelease',
        'Test::ReportPrereqs',
        'Test::Synopsis',
        'Test::TidyAll',
        'TravisCI::StatusBadge',
        'UploadToCPAN',
    );

    $self->add_plugins($_) for @plugins;
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

version 0.000011

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

This software is copyright (c) 2016 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
