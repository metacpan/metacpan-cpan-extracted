use strict;
use warnings;

package Dist::Zilla::PluginBundle::NGLENN;
# ABSTRACT: Dist::Zilla plugin configuration for me

our $VERSION = '0.03';

# Dependencies
use Moose 0.99;
use namespace::autoclean 0.09;

use Dist::Zilla 5.014; # default_jobs

use Dist::Zilla::PluginBundle::Filter ();
use Dist::Zilla::PluginBundle::Git 1.121010 ();

use Dist::Zilla::Plugin::Authority 1.006               ();
use Dist::Zilla::Plugin::Bugtracker 1.110              ();
use Dist::Zilla::Plugin::BumpVersionAfterRelease 0.003 (); # tweak Makefile.PL
use Dist::Zilla::Plugin::CheckChangesHasContent ();
use Dist::Zilla::Plugin::RunExtraTests          ();
use Dist::Zilla::Plugin::CheckMetaResources 0.001  ();
use Dist::Zilla::Plugin::CheckPrereqsIndexed 0.002 ();
use Dist::Zilla::Plugin::Git::Contributors 0.007   ();
use Dist::Zilla::Plugin::CopyFilesFromBuild           ();
use Dist::Zilla::Plugin::CPANFile                     ();
use Dist::Zilla::Plugin::Git::NextVersion             ();
# use Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch ();
use Dist::Zilla::Plugin::GithubMeta 0.36       ();
use Dist::Zilla::Plugin::TravisYML ();
use Dist::Zilla::Plugin::TravisCI::StatusBadge;
use Dist::Zilla::Plugin::InsertCopyright 0.001 ();
use Dist::Zilla::Plugin::MetaNoIndex ();
use Dist::Zilla::Plugin::MetaProvides::Package 1.14 (); # hides private packages
use Dist::Zilla::Plugin::MinimumPerl ();
use Dist::Zilla::Plugin::PodWeaver   ();
use Dist::Zilla::Plugin::PromptIfStale 0.011 ();
use Dist::Zilla::Plugin::Prereqs::AuthorDeps ();
use Dist::Zilla::Plugin::RewriteVersion ();
use Dist::Zilla::Plugin::ReadmeFromPod 0.19            (); # for dzil v5
use Dist::Zilla::Plugin::TaskWeaver 0.101620           ();
use Dist::Zilla::Plugin::Test::Compile 2.036           (); # various features
use Dist::Zilla::Plugin::Test::MinimumVersion 2.000003 ();
use Dist::Zilla::Plugin::Test::Perl::Critic ();
use Dist::Zilla::Plugin::Test::PodSpelling 2.006001 ();    # Pod::Wordlist
use Test::Portability::Files 0.06                   ();    # buggy before that
use Dist::Zilla::Plugin::Test::Portability ();
use Dist::Zilla::Plugin::Test::ReportPrereqs 0.016 (); # better reporting & bug fixes
use Dist::Zilla::Plugin::Test::Version ();

with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::Config::Slicer
  Dist::Zilla::Role::PluginBundle::PluginRemover
);

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
        exists $_[0]->payload->{tag_format} ? $_[0]->payload->{tag_format} : 'release-%v',;
    },
);

has version_regexp => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{version_regexp}
          ? $_[0]->payload->{version_regexp}
          : '^release-(.+)$',
          ;
    },
);

has weaver_config => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{weaver_config} || '@NGLENN' },
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

has authority => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{authority} ? $_[0]->payload->{authority} : 'cpan:NGLENN';
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

has auto_version => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{auto_version} },
);

sub configure {
    my $self = shift;

    my @push_to = ('origin');
    push @push_to, $self->git_remote if $self->git_remote ne 'origin';

    $self->add_plugins(

        # version number
        ( $self->auto_version ? 'AutoVersion' : 'RewriteVersion' ),

        # contributors
        (
            $self->no_git
            ? ()
            : 'Git::Contributors'
        ),

        # gather and prune
        (
            $self->no_git
            ? [ 'GatherDir' => { exclude_filename => [qw/README.mkdn cpanfile Makefile.PL/] }
              ] # core
            : [
                'Git::GatherDir' => { exclude_filename => [qw/README.mkdn cpanfile Makefile.PL/] }
            ]
        ),
        'PruneCruft',   # core
        'ManifestSkip', # core

        # file munging
        ( $self->auto_version ? 'PkgVersion' : () ),
        'InsertCopyright',
        (
            $self->is_task
            ? 'TaskWeaver'
            : [
                'PodWeaver' => {
                    config_plugin      => $self->weaver_config,
                    replacer           => 'replace_with_comment',
                    post_code_replacer => 'replace_with_nothing',
                }
            ]
        ),

        # generated distribution files
        'ReadmeFromPod', # in build dir
        'TravisCI::StatusBadge', # in readme file
        'License',       # core

        # Travis config file
        (
            $self->no_git
            ? ()
            : [
                'TravisYML' => {
                  build_branch => 'master',
                }
            ]
        ),

        # generated t/ tests
        [
            'Test::Compile' => {
                fake_home => 1,
                xt_mode   => 1,
            }
        ],
        (
            $self->no_minimum_perl
            ? ()
            : [ 'Test::MinimumVersion' => { max_target_perl => '5.010' } ]
        ),
        'Test::ReportPrereqs',

        # generated xt/ tests
        (
            $self->no_spellcheck ? ()
            : [
                'Test::PodSpelling' => $self->stopwords ? { stopwords => $self->stopwords } : ()
            ]
        ),
        (
            $self->no_critic ? ()
            : ('Test::Perl::Critic')
        ),
        'MetaTests',      # core
        'PodSyntaxTests', # core
        (
            $self->no_coverage
            ? ()
            : ('PodCoverageTests') # core
        ),
        [ 'Test::Portability' => { options => "test_one_dot = 0" } ],
        'Test::Version',

        # metadata
        [
            'Authority' => {
                authority  => $self->authority,
                do_munging => 0,
            }
        ],
        'MinimumPerl',
        (
            $self->auto_prereq
            ? [ 'AutoPrereqs' => { skip => "^t::lib" } ]
            : ()
        ),
        [
            MetaNoIndex => {
                directory => [qw/t xt examples corpus/],
                'package' => [qw/DB/]
            }
        ],
        [ 'MetaProvides::Package' => { meta_noindex => 1 } ], # AFTER MetaNoIndex
        (
            $self->darkpan
            ? ()
            : [
                GithubMeta => {
                    remote => [qw(origin github)],
                    issues => $self->github_issues,
                }
            ],
        ),
        (
            ( $self->no_git || $self->darkpan || !$self->github_issues ) ? (
                # fake out Pod::Weaver::Section::Support
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
                # fake out Pod::Weaver::Section::Support
                [
                    'MetaResources' => { map { ; "repository.$_" => "http://localhost/" } qw/url web/ }
                ],
              )
            : ()
        ),

        'Prereqs::AuthorDeps',
        'MetaYAML', # core
        'MetaJSON', # core
        'CPANFile',

        # build system
        'ExecDir',  # core
        'ShareDir', # core
        [ 'MakeMaker' => { eumm_version => '6.17', default_jobs => 9 } ], # core

        # are we up to date?
        [
            'PromptIfStale' => {
                modules           => [qw/Dist::Zilla Dist::Zilla::PluginBundle::NGLENN/],
                check_all_plugins => 1,
            }
        ],

        # copy files from build back to root for inclusion in VCS;
        # for auto_version we want cpanfile.  For embedded version we want Makefile.PL
        [
            CopyFilesFromBuild => { copy => $self->auto_version ? 'cpanfile' : 'Makefile.PL' }
        ],

        # manifest -- must come after all generated files
        'Manifest', # core

        # before release
        # (
        #     $self->no_git ? ()
        #     : ('Git::CheckFor::CorrectBranch')
        # ),
        (
            $self->no_git ? ()
            : [ 'Git::Check' => {
                  # these are copied to the root by CopyFilesFromBuild
                  allow_dirty => $self->auto_version ? 'cpanfile' : 'Makefile.PL'
                }
              ]
        ),
        'CheckMetaResources',
        'CheckPrereqsIndexed',
        'CheckChangesHasContent',
        [ 'RunExtraTests' => { default_jobs => 9 } ],
        'TestRelease',    # core
        'ConfirmRelease', # core

        # release
        ( $self->fake_release || $self->darkpan ? 'FakeRelease' : 'UploadToCPAN' ), # core

        # after release
        # Note -- NextRelease is here to get the ordering right with
        # git actions.  It is *also* a file munger that acts earlier

        (
            $self->no_git
            ? ()
            : ( [ 'Git::Tag' => { tag_format => $self->tag_format } ], )
        ),

        # bumps Changes
        'NextRelease', # core (also munges files)

        # bumps $VERSION, maybe
        ( $self->auto_version ? () : 'BumpVersionAfterRelease' ),

        (
            $self->no_git ? ()
            : (
                [
                    'Git::Commit' => 'Commit_Changes' => {
                        $self->auto_version ? ( commit_msg => "After release: timestamp Changes" )
                        : (
                            commit_msg        => "After release: bump \$VERSION and timestamp Changes",
                            allow_dirty       => [qw/Changes Makefile.PL/],
                            allow_dirty_match => '^lib|^bin',
                        )
                    }
                ],
                [ 'Git::Push' => { push_to => \@push_to } ],
            )
        ),

    );

}

__PACKAGE__->meta->make_immutable;

1;

#
# This file is part of Dist-Zilla-PluginBundle-NGLENN
#
# This software is Copyright (c) 2015 by Nathan Glenn.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::NGLENN - Dist::Zilla plugin configuration for me

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  # in dist.ini
  [@NGLENN]

=head1 DESCRIPTION

This is a L<Dist::Zilla> PluginBundle.  It is roughly equivalent to the
following dist.ini:

  ; version provider
  [RewriteVersion] ; also munges

  ; collect contributors list
  [Git::Contributors]

  ; choose files to include
  [Git::GatherDir]         ; everything from git ls-files
  exclude_filename = README.mkdn  ; skip this generated file
  exclude_filename = Makefile.PL  ; skip this generated file
  exclude_filename = cpanfile     ; skip this generated file

  [PruneCruft]        ; default stuff to skip
  [ManifestSkip]      ; if -f MANIFEST.SKIP, skip those, too

  ; file modifications
  [InsertCopyright    ; add copyright at "# COPYRIGHT"
  [PodWeaver]         ; generate Pod
  config_plugin = @NGLENN ; my own plugin allows Pod::WikiDoc
  replacer = replace_with_comment
  post_code_replacer = replace_with_nothing

  ; generated files
  [License]           ; boilerplate license
  [ReadmeFromPod]     ; from Pod (runs after PodWeaver)
  [TravisYML]         ; Travis-CI configuration
  build_branch = master
  ; t tests
  [Test::ReportPrereqs]   ; show prereqs in automated test output

  ; xt tests
  [Test::MinimumVersion]  ; xt/release/minimum-version.t
  max_target_perl = 5.010 ; don't use syntax/features past 5.10
  [Test::PodSpelling] ; xt/author/pod-spell.t
  [Test::Perl::Critic]; xt/author/critic.t
  [MetaTests]         ; xt/release/meta-yaml.t
  [PodSyntaxTests]    ; xt/release/pod-syntax.t
  [PodCoverageTests]  ; xt/release/pod-coverage.t
  [Test::Portability] ; xt/release/portability.t (of file name)
  options = test_one_dot = 0
  [Test::Version]     ; xt/release/test-version.t
  [Test::Compile]     ; xt/author/00-compile.t
  fake_home = 1       ; fakes $ENV{HOME} just in case
  xt_mode = 1         ; make sure all files compile

  ; metadata
  [AutoPrereqs]       ; find prereqs from code
  skip = ^t::lib

  [Authority]
  authority = cpan:NGLENN
  do_munging = 0

  [MinimumPerl]   ; determine minimum perl version

  [MetaNoIndex]       ; sets 'no_index' in META
  directory = t
  directory = xt
  directory = examples
  directory = corpus
  package = DB        ; just in case

  [GithubMeta]        ; set META resources
  remote = origin
  remote = github
  issues = 1

  [MetaProvides::Package] ; add 'provides' to META files
  meta_noindex = 1        ; respect prior no_index directives

  [Prereqs::AuthorDeps]   ; add authordeps as develop/requires
  [MetaYAML]              ; generate META.yml (v1.4)
  [MetaJSON]              ; generate META.json (v2)
  [CPANFile]              ; generate cpanfile

  ; build system
  [ExecDir]           ; include 'bin/*' as executables
  [ShareDir]          ; include 'share/' for File::ShareDir
  [MakeMaker]         ; create Makefile.PL
  eumm_version = 6.17
  default_jobs = 9

  ; manifest (after all generated files)
  [Manifest]          ; create MANIFEST

  ; copy cpanfile back to repo dis
  [CopyFilesFromBuild]
  copy = Makefile.PL

  ; before release

  [PromptIfStale]     ; check if our build tools are out of date
  module = Dist::Zilla
  module = Dist::Zilla::PluginBundle::NGLENN
  check_all_plugins = 1

  [Git::Check]        ; ensure all files checked in
  allow_dirty = dist.ini
  allow_dirty = Changes
  allow_dirty = cpanfile

  [CheckMetaResources]     ; ensure META has 'resources' data
  [CheckPrereqsIndexed]    ; ensure prereqs are on CPAN
  [CheckChangesHasContent] ; ensure Changes has been updated

  [RunExtraTests]   ; ensure xt/ tests pass
  default_jobs = 9

  [TestRelease]       ; ensure t/ tests pass
  [ConfirmRelease]    ; prompt before uploading

  ; releaser
  [UploadToCPAN]      ; uploads to CPAN

  ; after release
  [Git::Commit / Commit_Dirty_Files] ; commit Changes (as released)

  [Git::Tag]          ; tag repo with custom tag
  tag_format = release-%v

  ; NextRelease acts *during* pre-release to write $VERSION and
  ; timestamp to Changes and  *after* release to add a new {{$NEXT}}
  ; section, so to act at the right time after release, it must actually
  ; come after Commit_Dirty_Files but before Commit_Changes in the
  ; dist.ini.  It will still act during pre-release as usual

  [NextRelease]
  [BumpVersionAfterRelease]

  [Git::Commit / Commit_Changes] ; commit Changes (for new dev)

  [Git::Push]         ; push repo to remote
  push_to = origin

This distribution was forked from the DAGOLDEN plugin bundle. The
abstract should really be "Dist::Zilla configuration the way NGLENN,
who does it the way DAGOLDEN does it, does it", but that was too
long. I struggled with many complexities of writing a good dist.ini,
but found that David Golden had solved all of them.

I tweaked it slightly to fit my needs, most importantly to make
everything work on Windows. I will probably continue to pull changes
made to the originating DAGOLDEN distribution. See the changes file
for more information.

=head1 USAGE

To use this PluginBundle, just add it to your dist.ini.  You can provide
the following options:

=over 4

=item *

C<is_task> — this indicates whether C<TaskWeaver> or C<PodWeaver> should be used.

Default is 0.

=item *

C<authority> — specifies the C<x_authority> field for pause.  Defaults to 'cpan:NGLENN'.

=item *

C<auto_prereq> — this indicates whether C<AutoPrereqs> should be used or not.  Default is 1.

# C<auto_version> - this indicates whether C<AutoVersion> should be used or not. Default is 0.

=item *

C<darkpan> — for private code; uses C<FakeRelease> and fills in dummy repo/bugtracker data

=item *

C<fake_release> — swaps C<FakeRelease> for C<UploadToCPAN>. Mostly useful for testing a dist.ini without risking a real release.

=item *

C<git_remote> — where to push after release

=item *

C<github_issues> — whether to use github issue tracker. Defaults is 1.

=item *

C<stopwords> — add stopword for C<Test::PodSpelling> (can be repeated)

=item *

C<tag_format> — given to C<Git::Tag>.  Default is 'release-%v' to be more

robust than just the version number when parsing versions for
L<Git::NextVersion>

=item *

C<weaver_config> — specifies a L<Pod::Weaver> bundle.  Defaults to @NGLENN.

=item *

C<version_regexp> — given to L<Git::NextVersion>.  Default

is '^release-(.+)$'

=item *

C<no_git> — bypass all git-dependent plugins

=item *

C<no_critic> — omit C<Test::Perl::Critic> tests

=item *

C<no_spellcheck> — omit C<Test::PodSpelling> tests

=item *

C<no_coverage> — omit PodCoverage tests

=item *

C<no_minimum_perl> — omit C<Test::MinimumVersion> tests

=back

When running without git, C<GatherDir> is used instead of C<Git::GatherDir>.
and all git check and commit operations are disabled.

By default, versions are taken/rewritten in the source file using C<RewriteVersion>
and C<BumpVersionAfterRelease>. If the C<auto_version> option is true, the version
is set by C<AutoVersion> and munged with C<PkgVersion>.  For C<auto_version> the
generated C<cpanfile> is copied to the repo on build; otherwise, C<Makefile.PL> is
copied.

This PluginBundle now supports C<ConfigSlicer>, so you can pass in options to the
plugins used like this:

  [@NGLENN]
  Test::MinimumVersion.max_target_perl = 5.014
  ExecDir.dir = scripts

This PluginBundle also supports C<PluginRemover>, so dropping a plugin is as easy as this:

  [@NGLENN]
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

=item *

L<Dist::Zilla::PluginBundle::DAGOLDEN>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/garfieldnate/Dist-Zilla-PluginBundle-NGLENN/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/garfieldnate/Dist-Zilla-PluginBundle-NGLENN>

  git clone https://github.com/garfieldnate/Dist-Zilla-PluginBundle-NGLENN.git

=head1 AUTHOR

Nate Glenn <nglenn@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Christian Walde David Golden Eric Johnson Karen Etheridge Nathan Glenn Philippe Bruhat (BooK) Sergey Romanov

=over 4

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Eric Johnson <eric.git@iijo.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Nathan Glenn <garfieldnate@gmail.com>

=item *

Philippe Bruhat (BooK) <book@cpan.org>

=item *

Sergey Romanov <complefor@rambler.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Nathan Glenn.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
