package Dist::Zilla::PluginBundle::Author::GTERMARS;

use Moose;
with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::PluginRemover
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);
use namespace::autoclean;

our $VERSION = '0.05';

has fake_release => (
  is         => 'ro',
  isa        => 'Bool',
  lazy_build => 1,
);
sub _build_fake_release {
  my $self = shift;
  return $ENV{FAKE_RELEASE} // $self->payload->{fake_release} // 0;
}

sub configure {
  my $self = shift;

  $self->add_plugins(
    ###########################################################################
    # Ensure we're using the correct Author Bundle
    [ 'PromptIfStale' => 'Stale author bundle' => {
        phase  => 'build',
        module => 'Dist::Zilla::PluginBundle::Author::GTERMARS',
      },
    ],

    ###########################################################################
    # Gather up all the files we need in our distribution
    [ 'GatherDir' => {
        exclude_filename => [qw( dist.ini cpanfile )],
      },
    ],
    [ 'ExecDir' => {
      dir => (-d 'script' ? 'script' : 'bin'),
      },
    ],
    [ 'ShareDir' ],
    [ 'PruneCruft' ],

    ###########################################################################
    # Auto-generate files as needed...
    # ... Makefile.PL
    [ 'MakeMaker' ],
    # ... MANIFEST
    [ 'Manifest' ],
    # ... LICENSE
    [ 'License' ],
    # ... README (both .md and .txt)
    [ 'ReadmeAnyFromPod' => 'ReadmeGfmInRoot' ],
    [ 'ReadmeAnyFromPod' => 'ReadmeInDist' ],
    # ... Dependencies
    [ 'Prereqs::FromCPANfile' ],
    [ 'Prereqs::AuthorDeps' ],
    # ... META
    [ 'MetaYAML' ],
    [ 'MetaJSON' ],
    [ 'MetaNoIndex' => {
        directory => [ qw( t xt ), grep { -d $_ } qw( examples inc local share ) ],
      },
    ],
    # ... Tests
    [ 'MetaTests' ],
    [ 'Test::ReportPrereqs' => {
        verify_prereqs => 1,
      },
    ],
    [ 'Test::NoTabs' ],
    [ 'Test::EOL' ],
    [ 'Test::EOF' ],
    [ 'Test::MinimumVersion' ],
    [ 'Test::Synopsis' ],
    [ 'PodSyntaxTests' ],
    [ 'PodCoverageTests' ],
    [ 'Test::PodSpelling' ],
    [ 'Test::NoBreakpoints' ],
    [ 'Test::CleanNamespaces' ],
    [ 'Test::DiagINC' ],
    [ 'Test::UnusedVars' ],
    [ 'Test::Kwalitee' ],
    [ 'Test::Compile' => {
        fake_home        => 1,
        filename         => 't/01-compile.t',
        bail_out_on_fail => 1,
      },
    ],

    ###########################################################################
    # Additional Metadata
    ( ($ENV{AUTOMATED_TESTING} || $ENV{CI})
      ? ()
      : ([ 'GitHub::Meta' ])
    ),
    [ 'StaticInstall', {
        mode => 'auto',
      },
    ],

    ###########################################################################
    # Run "xt/" tests, but don't include them in the release.
    [ 'RunExtraTests', {
        default_jobs => 8,
      },
    ],

    ###########################################################################
    # Munge existing files
    [ 'NextRelease' ],
    [ 'RewriteVersion' ],

    ###########################################################################
    # Release
    # ... before release
    [ 'PromptIfStale' => 'Stale modules, release' => {
        phase             => 'release',
        check_all_plugins => 1,
        check_all_prereqs => 1,
        skip              => [qw( ExtUtils::MakeMaker )],
      },
    ],
    [ 'Git::CheckFor::MergeConflicts' ],
    [ 'Git::CheckFor::CorrectBranch' ],
    [ 'EnsureChangesHasContent' ],
    [ 'EnsureMinimumPerl' ],
    [ 'Git::Check' => 'initial check' ],
    [ 'TestRelease' ],
    [ 'Git::Check' => 'after tests' ],
    [ 'GitHub::RequireGreenBuild' ],
    [ 'CheckIssues' ],
    # ... do the release
    ( $self->fake_release
      ? ( [ 'FakeRelease' ] )
      : ( [ 'ConfirmRelease' ], [ 'UploadToCPAN' ], [ 'GitHub::Update' ] )
    ),
    # ... after release; commit Changes and Tag release
    [ 'Git::Commit' => 'Commit Changes' => {
        commit_msg => 'Release v%V',
      },
    ],
    [ 'Git::Tag' ],
    # ... after release; save Release artifacts
    [ 'Git::CommitBuild' => {
        branch          => '',
        release_branch  => 'releases',
        release_message => 'Release - v%v',
      },
    ],
    # ... after release; bump Version for next release
    [ 'BumpVersionAfterRelease' ],
    [ 'Git::Commit' => 'Commit Version Bump' => {
        allow_dirty_match => '^lib/',
        commit_msg        => 'Version bump.',
      },
    ],
    # ... after release; push changes up to Git
    ( $self->fake_release
      ? ()
      : ( [ 'Git::Push', { push_to => [ 'origin', 'origin releases:releases' ] } ] )
    ),
  );
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Dist::Zilla::PluginBundle::Author::GTERMARS - Plugin Bundle for distributions built by GTERMARS

=head1 SYNOPSIS

In your F<dist.ini>:

  [@Author::GTERMARS]

=head1 DESCRIPTION

This is the C<Dist::Zilla> plugin bundle that GTERMARS uses to build his
distributions.

It is I<roughly> equivalent to the following:

  ; ==============================================================================
  ; Ensure we're using the correct Author Bundle
  [PromptIfStale / Stale author bundle]
  phase = build
  module = Dist::Zilla::PluginBundle::Author::GTERMARS

  ; ==============================================================================
  ; Gather up all the files we need in our distribution
  [GatherDir]
  exclude_filename = dist.ini
  exclude_filename = cpanfile
  [ExecDir]
  dir = (-d 'script' ? 'script' : 'bin')
  [ShareDir]
  [PruneCruft]

  ; ==============================================================================
  ; Auto-generate files as needed...
  ; ... Makefile.PL
  [MakeMaker]
  ; ... MANIFEST
  [Manifest]
  ; ... LICENSE
  [License]
  ; ... README file(s)
  [ReadmeAnyFromPod / ReadmeGfmInRoot]
  [ReadmeAnyFromPod / ReadmeInDist]
  ; ... Dependencies
  [Prereqs::FromCPANfile]
  [Prereqs::AuthorDeps]
  ; ... META
  [MetaYAML]
  [MetaJSON]
  [MetaNoIndex]
  directory = examples
  directory = inc
  directory = local
  directory = share
  directory = t
  directory = xt
  ; ... Tests
  [MetaTests]
  [Test::ReportPrereqs]
  verify_prereqs = 1
  [Test::NoTabs]
  [Test::EOL]
  [Test::EOF]
  [Test::MinimumVersion]
  [Test::Synopsis]
  [PodSyntaxTests]
  [PodCoverageTests]
  [Test::PodSpelling]
  [Test::NoBreakpoints]
  [Test::CleanNamespaces]
  [Test::DiagINC]
  [Test::UnusedVars]
  [Test::Kwalitee]
  [Test::Compile]
  fake_home = 1
  filename = t/01-compile.t
  bail_out_on_fail = 1

  ; ==============================================================================
  ; Additional Metadata
  [GitHub::Meta]
  [StaticInstall]
  mode = auto

  ; ==============================================================================
  ; Run "xt/" tests, but don't include them in the release.
  [RunExtraTests]
  default_jobs = 8

  ; ==============================================================================
  ; Munge existing files
  [NextRelease]
  [RewriteVersion]

  ; ==============================================================================
  ; Release

  ; ... before release
  [PromptIfStale / Stale modules, release]
  phase = release
  check_all_plugins = 1
  check_all_prereqs = 1
  skip = ExtUtils::MakeMaker
  [Git::CheckFor::MergeConflicts]
  [Git::CheckFor::CorrectBranch]
  [EnsureChangesHasContent]
  [EnsureMinimumPerl]
  [Git::Check / initial check]
  [TestRelease]
  [Git::Check / after tests]
  [GitHub::RequireGreenBuild]
  [CheckIssues]

  ; ... do the release (unless "fake_release" is set)
  [ConfirmRelease]
  [UploadToCPAN]
  [GitHub::Update]

  ; ... after release; commit Changes and Tag release
  [Git::Commit / Commit Changes]
  commit_msg = Release v%V
  [Git::Tag]

  ; ... after release; save Release artifacts
  [Git::CommitBuild]
  branch =
  release_branch = releases
  release_message = Release - v%v

  ; ... after release; bump Version for next release
  [BumpVersionAfterRelease]
  [Git::Commit / Commit Version Bump]
  allow_dirty_match = ^lib/
  commit_msg = Version bump.

  ; ... after release; push changes up to Git (unless "fake_release" is set)
  [Git::Push]
  push_to = origin
  push_to = origin releases:releases

=head1 CUSTOMIZATION

=head2 Our Configuration Options

=over

=item fake_release

A boolean option, which when set, removes C<[ConfirmRelease]>,
C<[UploadToCPAN]>, and C<[GitHub::Update]>, replacing them with
C<[FakeRelease]>.

Defaults to false, and can also be set with the C<FAKE_RELEASE=1> environment
variable.

=back

=head2 POD Coverage

Subroutines can be considered "covered" for POD Coverage checks, by adding a
directive to the POD itself, as described in L<Pod::CoverageTrustPod>:

  =for Pod::Coverage foo bar baz

=head2 POD Spelling

Stopwords for POD Spelling checks can be added by adding a directive to the POD
itself, as described in L<Pod::Spell>:

  =for stopwords foo bar baz

=head2 Providing Plugin Configuration

This plugin bundle uses C<Dist::Zilla::Role::PluginBundle::Config::Slicer>,
which allows you to provide plugin-specific configuration like this:

  [@Author::GTERMARS]
  GatherDir.exclude_filename = cpanfile

=head2 Removing Plugins

This plugin bundle uses C<Dist::Zilla::Role::PluginBundle::Remover>, allowing
you to remove specific plugins like this:

  [@Author::GTERMARS]
  -remove = GitHub::Meta
  -remove = RunExtraTests

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2020-, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

=over

=item L<Dist::Zilla>

=back

=cut
