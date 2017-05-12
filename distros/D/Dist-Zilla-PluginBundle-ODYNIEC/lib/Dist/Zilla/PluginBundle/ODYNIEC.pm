use strict;
use warnings;

package Dist::Zilla::PluginBundle::ODYNIEC;
our $VERSION = '0.021'; # VERSION

# Dependencies
use autodie 2.00;
use Moose 0.99;
use Moose::Autobox;
use namespace::autoclean 0.09;

use Dist::Zilla 5; # Number 5 is ALIVE!

use Dist::Zilla::PluginBundle::Filter ();
use Dist::Zilla::PluginBundle::Git 1.121010 ();

use Dist::Zilla::Plugin::Bugtracker 1.110 ();
use Dist::Zilla::Plugin::CheckChangesHasContent ();
use Dist::Zilla::Plugin::CheckExtraTests        ();
use Dist::Zilla::Plugin::CheckMetaResources 0.001  ();
use Dist::Zilla::Plugin::CheckPrereqsIndexed 0.002 ();
use Dist::Zilla::Plugin::ContributorsFromGit 0.004 ();
use Dist::Zilla::Plugin::CopyFilesFromBuild ();
use Dist::Zilla::Plugin::CPANFile           ();
use Dist::Zilla::Plugin::Git::NextVersion   ();
use Dist::Zilla::Plugin::GithubMeta 0.36       ();
use Dist::Zilla::Plugin::InsertCopyright 0.001 ();
use Dist::Zilla::Plugin::MetaNoIndex ();
use Dist::Zilla::Plugin::MetaProvides::Package 1.14 (); # hides private packages
use Dist::Zilla::Plugin::MinimumPerl ();
use Dist::Zilla::Plugin::OurPkgVersion 0.004 ();        # TRIAL comment support
use Dist::Zilla::Plugin::PodWeaver ();
use Dist::Zilla::Plugin::ReadmeAnyFromPod ();
use Dist::Zilla::Plugin::TaskWeaver 0.101620           ();
use Dist::Zilla::Plugin::Test::Compile 2.036           (); # various features
use Dist::Zilla::Plugin::Test::CPAN::Changes ();
use Dist::Zilla::Plugin::Test::MinimumVersion 2.000003 ();
use Dist::Zilla::Plugin::Test::Perl::Critic ();
use Dist::Zilla::Plugin::Test::PodSpelling 2.006001 ();    # Pod::Wordlist
use Test::Portability::Files 0.06                   ();    # buggy before that
use Dist::Zilla::Plugin::Test::Portability ();
use Dist::Zilla::Plugin::Test::ReportPrereqs 0.008 ();     # warn on unsatisfied
use Dist::Zilla::Plugin::Test::Version ();

with 'Dist::Zilla::Role::PluginBundle::Easy';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';
with 'Dist::Zilla::Role::PluginBundle::PluginRemover';

sub mvp_multivalue_args { qw/stopwords/ }

has stopwords => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    lazy    => 1,
    default => sub { 
        exists $_[0]->payload->{stopwords} ? $_[0]->payload->{stopwords} : undef;
    },
);

has fake_release => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{fake_release} },
);

has no_git => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{no_git} },
);

has no_critic => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{no_critic} ? $_[0]->payload->{no_critic} : 0;
    },
);

has no_spellcheck => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{no_spellcheck}
          ? $_[0]->payload->{no_spellcheck}
          : 0;
    },
);

has no_coverage => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{no_coverage}
          ? $_[0]->payload->{no_coverage}
          : 0;
    },
);

has no_minimum_perl => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{no_minimum_perl}
          ? $_[0]->payload->{no_minimum_perl}
          : 0;
    },
);

has is_task => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{is_task} },
);

has auto_prereq => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{auto_prereq} ? $_[0]->payload->{auto_prereq} : 1;
    },
);

has tag_format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{tag_format} ? $_[0]->payload->{tag_format} : 'v%v',;
    },
);

has version_regexp => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{version_regexp}
          ? $_[0]->payload->{version_regexp}
          : '^v(.+)$',
          ;
    },
);

has weaver_config => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{weaver_config} || '@ODYNIEC' },
);

has github_issues => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{github_issues} ? $_[0]->payload->{github_issues} : 1;
    },
);

has git_remote => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{git_remote} ? $_[0]->payload->{git_remote} : 'origin',;
    },
);

has darkpan => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{darkpan} ? $_[0]->payload->{darkpan} : 0;
    },
);

sub configure {
    my $self = shift;

    my @push_to = ();
    push @push_to, $self->git_remote;

    $self->add_plugins(

        # Version provider
        (
            $self->no_git
            ? 'AutoVersion' # (core)
            : [ 'Git::NextVersion' =>
                { version_regexp => $self->version_regexp } ]
                # Get version from last release tag
        ),

        # Collect contributors list
        (
            $self->no_git
            ? ()
            : 'ContributorsFromGit'
        ),

        # Choose files to include
        (
            $self->no_git
            ? [
                'GatherDir' =>
                  { exclude_filename => [qw/META.json cpanfile/] }
              ] # (core)
            : [
                'Git::GatherDir' =>
                  { exclude_filename => [qw/META.json cpanfile/] }
            ] # Everything from git ls-files
        ),
        'PruneCruft',   # Default stuff to skip (core)
        'ManifestSkip', # If -f MANIFEST.SKIP, skip those, too (core)

        # File modifications
        'OurPkgVersion',    # Add $VERSION = ... to all files
        'InsertCopyright',  # Add copyright at "# COPYRIGHT"
        (
            $self->is_task
            ? 'TaskWeaver'
            : [ 'PodWeaver' => { config_plugin => $self->weaver_config } ]
            # Generate Pod
        ),

        # Generated distribution files
        'License',       # Boilerplate license (core)
        [
            'ReadmeAnyFromPod' => 'ReadmePodInRoot' => { type => 'pod' }
            # For README.pod
        ],
        
        # Generated t/ tests
        'Test::ReportPrereqs',  # Show prereqs in automated test output

        # Generated xt/ tests
        (
            $self->no_minimum_perl
            ? ()
            : [ 'Test::MinimumVersion' => { max_target_perl => '5.010' } ]
            # Don't use syntax/features past 5.10
        ),
        (
            $self->no_spellcheck ? ()
            : [ 'Test::PodSpelling' => $self->stopwords ? { stopwords => $self->stopwords } : () ]
            # xt/author/pod-spell.t
        ),
        (
            $self->no_critic ? ()
            : ('Test::Perl::Critic')
            # xt/author/critic.t
        ),
        'MetaTests',      # xt/release/meta-yaml.t (core)
        'PodSyntaxTests', # xt/release/pod-syntax.t (core)
        (
            $self->no_coverage
            ? ()
            : ('PodCoverageTests') # xt/release/pod-coverage.t (core)
        ),
        # xt/release/portability.t (of file name)
        [ 'Test::Portability' => { options => "test_one_dot = 0" } ],
        'Test::Version',  # xt/release/test-version.t
        [
            'Test::Compile' => {
                fake_home => 1,   # Fake $ENV{HOME} just in case
            }
        ],
        'Test::CPAN::Changes',  # xt/release/cpan-changes.t

        # Metadata
        (
            $self->auto_prereq
            ? [ 'AutoPrereqs' => { skip => "^t::lib" } ]
            # Find prereqs from code (core)
            : ()
        ),
        'MinimumPerl',  # Determine minimum Perl version
        [
            # Sets 'no_index' in META
            MetaNoIndex => {
                directory => [qw/t xt examples corpus/],
                'package' => [qw/DB/]   # Just in case
            }
        ],
        (
            $self->darkpan
            ? ()
            : [
                # Set META resources
                GithubMeta => {
                    remote => [qw(origin github)],
                    issues => $self->github_issues,
                }
            ],
        ),
        # Add 'provides' to META files
        [ 'MetaProvides::Package' =>
            { meta_noindex => 1 } ],  # Respect prior no_index directives
        (
            ( $self->no_git || $self->darkpan || !$self->github_issues ) ? (
                # Fake out Pod::Weaver::Section::Support
                [
                    'Bugtracker' =>
                      { mailto => '', $self->darkpan ? ( web => "http://localhost/" ) : () }
                ],
              )
            : ()
        ),
        (
            ( $self->no_git || $self->darkpan )
            ? (
                # Fake out Pod::Weaver::Section::Support
                [
                    'MetaResources' => { map { ; "repository.$_" => "http://localhost/" } qw/url web/ }
                ],
              )
            : ()
        ),

        'MetaYAML', # Generate META.yml (v1.4) (core)
        'MetaJSON', # Generate META.json (vw) (core)
        'CPANFile',

        # Build system
        'ExecDir',  # Include 'bin/*' as executables (core)
        'ShareDir', # Include 'share/' for File::ShareDir (core)
        [ 'MakeMaker' => { eumm_version => '6.17' } ], # Create Makefile.PL (core)

        # Copy files from build back to root for inclusion in VCS
        [ CopyFilesFromBuild => { copy => 'cpanfile', } ],

        # Manifest (after all generated files)
        'Manifest',   # Create MANIFEST (core)

        # Before release
        (
            $self->no_git
            ? ()
            : [ 'Git::Check' => { allow_dirty => [qw/dist.ini Changes cpanfile README.pod/] } ]
            # Ensure all files checked in
        ),
        'CheckMetaResources',       # Ensure META has 'resources' data
        'CheckPrereqsIndexed',      # Ensure prereqs are on CPAN
        'CheckChangesHasContent',   # Ensure Changes has been updated
        'CheckExtraTests',          # Ensure xt/tests pass
        'TestRelease',              # Ensure t/ tests pass (core)
        'ConfirmRelease',           # Prompt before uploading (core)

        # Release
        ( $self->fake_release || $self->darkpan ? 'FakeRelease' : 'UploadToCPAN' ),
        # Upload to CPAN (core)

        # After release

        [ 'NextRelease' => { format => '%-9v %{yyyy-MM-dd}d' } ],

        (
            $self->no_git
            ? ()
            : (
                [ 'Git::Commit' =>
                    { allow_dirty => [qw/dist.ini Changes README.pod cpanfile/] } ],
                # Commit Changes
                [
                    'Git::Tag' => {
                        tag_format => $self->tag_format,
                        tag_message => 'Version %v'
                    }
                ],
                # Tag repo with custom tag
                [ 'Git::Push' => { push_to => \@push_to } ],
                # Push repo to remote
            )
        ),

    );

}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Dist::Zilla configuration the way ODYNIEC does it
#
# This file is part of Dist-Zilla-PluginBundle-ODYNIEC
#
# This software is Copyright (c) 2014 by Michal Wojciechowski.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::ODYNIEC - Dist::Zilla configuration the way ODYNIEC does it

=head1 VERSION

version 0.021

=head1 SYNOPSIS

  # in dist.ini
  [@ODYNIEC]

=head1 DESCRIPTION

This is a L<Dist::Zilla> PluginBundle based on
L<Dist::Zilla::PluginBundle::DAGOLDEN>, which was created by David Golden.
It is roughly equivalent to the following dist.ini:

  ; Version provider
  [Git::NextVersion]  ; Get version from last release tag
  version_regexp = ^v(.+)$

  ; Collect contributors list
  [ContributorsFromGit]

  ; Choose files to include
  [Git::GatherDir]    ; Everything from git ls-files
  exclude_filename = META.json  ; Skip this generated file
  [PruneCruft]        ; Default stuff to skip
  [ManifestSkip]      ; If -f MANIFEST.SKIP, skip those, too

  ; File modifications
  [OurPkgVersion]     ; Add $VERSION = ... to all files
  [InsertCopyright    ; Add copyright at "# COPYRIGHT"
  [PodWeaver]         ; Generate Pod
  config_plugin = @ODYNIEC ; For Pod::WikiDoc

  ; generated files
  [License]           ; Boilerplate license (core)
  [ReadmeAnyFromPod / ReadmePodInRoot]     ; For README.pod
  type = pod

  ; Generated t/ tests
  [Test::ReportPrereqs]   ; Show prereqs in automated test output

  ; Generated xt/ tests
  [Test::MinimumVersion]  ; xt/release/minimum-version.t
  max_target_perl = 5.010 ; Don't use syntax/features past 5.10
  [Test::PodSpelling] ; xt/author/pod-spell.t
  [Test::Perl::Critic]; xt/author/critic.t
  [MetaTests]         ; xt/release/meta-yaml.t (core)
  [PodSyntaxTests]    ; xt/release/pod-syntax.t (core)
  [PodCoverageTests]  ; xt/release/pod-coverage.t (core)
  [Test::Portability] ; xt/release/portability.t (of file name)
  options = test_one_dot = 0
  [Test::Version]     ; xt/release/test-version.t
  [Test::Compile]     ; xt/author/00-compile.t
  fake_home = 1       ; Fake $ENV{HOME} just in case
  [Test::CPAN::Changes]   ; xt/release/cpan-changes.t

  ; Metadata
  [AutoPrereqs]       ; Find prereqs from code (core)
  skip = ^t::lib

  [MinimumPerl]       ; Determine minimum Perl version

  [MetaNoIndex]       ; Sets 'no_index' in META
  directory = t
  directory = xt
  directory = examples
  directory = corpus
  package = DB        ; Just in case

  [GithubMeta]        ; Set META resources
  remote = origin
  remote = github
  issues = 1

  [MetaProvides::Package] ; Add 'provides' to META files
  meta_noindex = 1        ; Respect prior no_index directives

  [MetaYAML]          ; Generate META.yml (v1.4) (core)
  [MetaJSON]          ; Generate META.json (v2) (core)
  [CPANFile]          ; Generate cpanfile

  ; Build system
  [ExecDir]           ; Include 'bin/*' as executables (core)
  [ShareDir]          ; Include 'share/' for File::ShareDir (core)
  [MakeMaker]         ; Create Makefile.PL (core)
  eumm_version = 6.17

  ; Copy files from build back to root for inclusion in VCS
  [CopyFilesFromBuild]
  copy = cpanfile

  ; Manifest (after all generated files)
  [Manifest]          ; Create MANIFEST (core)

  ; Before release
  [Git::Check]        ; Ensure all files checked in
  allow_dirty = dist.ini
  allow_dirty = Changes
  allow_dirty = cpanfile
  allow_dirty = README.pod

  [CheckMetaResources]     ; Ensure META has 'resources' data
  [CheckPrereqsIndexed]    ; Ensure prereqs are on CPAN
  [CheckChangesHasContent] ; Ensure Changes has been updated
  [CheckExtraTests]   ; Ensure xt/ tests pass
  [TestRelease]       ; Ensure t/ tests pass (core)
  [ConfirmRelease]    ; Prompt before uploading (core)

  ; Release
  [UploadToCPAN]      ; Upload to CPAN (core)

  ; After release

  ; NextRelease acts *during* pre-release to write $VERSION and
  ; timestamp to Changes and  *after* release to add a new {{$NEXT}}
  ; section, so to act at the right time after release, it must actually
  ; come after Commit_Dirty_Files but before Commit_Changes in the
  ; dist.ini.  It will still act during pre-release as usual

  [NextRelease]
  format = %-9v %{yyyy-MM-dd}d

  [Git::Commit] ; Commit Changes
  allow_dirty = dist.ini
  allow_dirty = Changes
  allow_dirty = README.pod
  allow_dirty = cpanfile

  [Git::Tag]          ; Tag repo with custom tag
  tag_message = Version %v

  [Git::Push]         ; Push repo to remote

=head1 USAGE

To use this PluginBundle, just add it to your dist.ini.  You can provide
the following options:

=over 4

=item *

C<is_task> -- this indicates whether C<TaskWeaver> or C<PodWeaver> should be used.

Default is 0.

=item *

C<auto_prereq> -- this indicates whether C<AutoPrereqs> should be used or not.  Default is 1.

=item *

C<darkpan> -- for private code; uses C<FakeRelease> and fills in dummy repo/bugtracker data

=item *

C<fake_release> -- swaps C<FakeRelease> for C<UploadToCPAN>. Mostly useful for testing a dist.ini without risking a real release.

=item *

C<git_remote> -- where to push after release

=item *

C<github_issues> -- whether to use github issue tracker. Defaults is 1.

=item *

C<stopwords> -- add stopword for C<Test::PodSpelling> (can be repeated)

=item *

C<tag_format> -- given to C<Git::Tag>. Default is 'v%v'.

=item *

C<weaver_config> -- specifies a L<Pod::Weaver> bundle. Defaults to @ODYNIEC.

=item *

C<version_regexp> -- given to L<Git::NextVersion>. Default is '^v(.+)$'

=item *

C<no_git> -- bypass all git-dependent plugins

=item *

C<no_critic> -- omit C<Test::Perl::Critic> tests

=item *

C<no_spellcheck> -- omit C<Test::PodSpelling> tests

=item *

C<no_coverage> -- omit PodCoverage tests

=item *

C<no_minimum_perl> -- omit C<Test::MinimumVersion> tests

=back

When running without git, C<GatherDir> is used instead of C<Git::GatherDir>,
C<AutoVersion> is used instead of C<Git::NextVersion>, and all git check and
commit operations are disabled.

This PluginBundle now supports C<ConfigSlicer>, so you can pass in options to the
plugins used like this:

  [@ODYNIEC]
  Test::MinimumVersion.max_target_perl = 5.014
  ExecDir.dir = scripts

This PluginBundle also supports C<PluginRemover>, so dropping a plugin is as easy as this:

  [@ODYNIEC]
  -remove = Test::Portability

=for Pod::Coverage configure mvp_multivalue_args

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=item *

L<Dist::Zilla::Plugin::TaskWeaver>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/odyniec/p5-Dist-Zilla-PluginBundle-ODYNIEC/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/odyniec/p5-Dist-Zilla-PluginBundle-ODYNIEC>

  git clone https://github.com/odyniec/p5-Dist-Zilla-PluginBundle-ODYNIEC.git

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Michal Wojciechowski <odyniec@cpan.org>

=back

=head1 CONTRIBUTORS

=over 4

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

Eric Johnson <eric.git@iijo.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Michal Wojciechowski <odyniec@odyniec.net>

=item *

Michał Wojciechowski <odyniec@odyniec.eu.org>

=item *

Philippe Bruhat (BooK) <book@cpan.org>

=item *

Sergey Romanov <complefor@rambler.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Michal Wojciechowski.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
