use strict;
use warnings;

package Dist::Zilla::PluginBundle::SILEX;
# ABSTRACT: Dist::Zilla configuration the way SILEX does it
our $VERSION = 'v0.0.2'; # VERSION

# Dependencies
use autodie 2.00;
use Moose 0.99;
use namespace::autoclean 0.09;

use Dist::Zilla 5; # Number 5 is ALIVE!

use Dist::Zilla::PluginBundle::DAGOLDEN 0.062 ();

use Dist::Zilla::Plugin::ReadmeAnyFromPod 0.133360 ();

use Dist::Zilla::Util ();
use List::MoreUtils;

extends 'Dist::Zilla::PluginBundle::DAGOLDEN';

with 'Dist::Zilla::Role::PluginBundle::PluginRemover';

sub mvp_multivalue_args {qw(
    RemovePrereqs.remove
    stopwords
)}

has authority => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{authority} ? $_[0]->payload->{authority} : 'cpan:SILEX';
    },
);

has weaver_config => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{weaver_config} || '@SILEX' },
);

has silex_git => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{silex_git} ? $_[0]->payload->{silex_git} : q{};
    },
);

sub _remove_plugins {
    my ( $self, @remove_list ) = @_;

    my $plugins = $self->plugins;
    for my $i ( reverse 0 .. $#{$plugins} ) {
        splice @$plugins, $i, 1 if List::MoreUtils::any(
            sub { $plugins->[$i][1] eq Dist::Zilla::Util->expand_config_package_name($_); },
            @remove_list,
        );
    }
}

sub _update_plugins {
    my ( $self, @update_list ) = @_;

    my $plugins = $self->plugins;
    for my $i ( reverse 0 .. $#{$plugins} ) {
        for my $update (@update_list) {
            my ( $k, @v ) = @$update;
            next
                unless
                    $plugins->[$i][1] eq Dist::Zilla::Util->expand_config_package_name( $update->[0] )
                    || $plugins->[$i][0] eq $update->[0]
                    ;
            $plugins->[$i][2] = $update->[1]
        }
    }
}

after configure => sub {
    my $self = shift;

    $self->_update_plugins(
        [
            PromptIfStale => {
                modules           => [qw/Dist::Zilla Dist::Zilla::PluginBundle::SILEX/],
                check_all_plugins => 1,
            },
        ],
        [
            MetaNoIndex => {
                directory => [qw/t xt examples corpus public/],
                'package' => [qw/DB/]
            }
        ],
        [
            'Git::NextVersion' => {
                first_version     => 'v0.0.1',
                version_by_branch => 1,
                version_regexp    => $self->version_regexp,
            },
        ],
        [
            'Git::Tag' => {
                branch      => 'master',
                tag_format  => $self->tag_format,
                tag_message => 'Release %v',
            },
        ],
        [
            'Git::Check' => {
                allow_dirty => [qw/
                    Changes
                    README.mkdn
                    cpanfile
                    dist.ini
                /],
            },
        ],
        [
            '@SILEX/Commit_Dirty_Files' => {
                commit_msg  => 'release-%v%n%n%c',
                allow_dirty => [qw/
                    Changes
                    README.mkdn
                    cpanfile
                    dist.ini
                /],
            },
        ],
    );

    $self->add_plugins(
        [ ReadmeAnyFromPod => 'MarkdownInRoot' ],
        'Prereqs',
        [ Prereqs => Runtime_Requires   => { -phase => 'runtime', -relationship => 'requires'   } ],
        [ Prereqs => Runtime_Recommends => { -phase => 'runtime', -relationship => 'recommends' } ],
        [ Prereqs => Test_Requires      => { -phase => 'test',    -relationship => 'requires'   } ],
        [ RemovePrereqs => { remove => [qw/ strict warnings /] } ],
    );

    if ( $self->silex_git ) {
        $self->_remove_plugins(qw/ GithubMeta /);

        my @params = (
            [
                Bugtracker => {
                    mailto => 'dev@silex.kr',
                    web    => 'https://bz4.silex.kr',
                },
            ],
            [
                MetaResources => {
                    'repository.type' => 'git',
                    'repository.url'  => 'git://git@git.silex.kr:' . $self->silex_git .'.git',
                    'repository.web'  => 'https://git.silex.kr/' . $self->silex_git,
                    'homepage'        => 'https://project.silex.kr/' . $self->silex_git,
                },
            ],
        );
        $self->darkpan ? $self->_update_plugins(@params) : $self->add_plugins(@params);
    }
};

__PACKAGE__->meta->make_immutable;

1;

#
# This file is part of Dist-Zilla-PluginBundle-SILEX
#
# This software is copyright (c) 2014 by SILEX.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::SILEX - Dist::Zilla configuration the way SILEX does it

=head1 VERSION

version v0.0.2

=head1 SYNOPSIS

  # in dist.ini
  [@SILEX]

  # using local git
  [@SILEX]
  silex_git = silex/myrepo

  # using github & darkpan
  [@SILEX]
  darkpan = 1

  # using local git & darkpan
  [@SILEX]
  silex_git = silex/myrepo
  darkpan = 1

=head1 DESCRIPTION

This is a L<Dist::Zilla> PluginBundle.  It is roughly equivalent to the
following dist.ini:

  ; version provider
  [Git::NextVersion]  ; get version from last release tag
  first_version     = v0.0.1
  version_by_branch = 1
  version_regexp    = ^release-(.+)$

  ; collect contributors list
  [ContributorsFromGit]

  ; choose files to include
  [Git::GatherDir]         ; everything from git ls-files
  exclude_filename = README.pod   ; skip this generated file
  exclude_filename = META.json    ; skip this generated file

  [PruneCruft]        ; default stuff to skip
  [ManifestSkip]      ; if -f MANIFEST.SKIP, skip those, too

  ; file modifications
  [OurPkgVersion]     ; add $VERSION = ... to all files
  [InsertCopyright]   ; add copyright at "# COPYRIGHT"
  [PodWeaver]         ; generate Pod
  config_plugin = @SILEX ; my own plugin allows Pod::WikiDoc
  replacer = replace_with_comment
  post_code_replacer = replace_with_nothing

  ; generated files
  [License]                           ; boilerplate license
  [ReadmeFromPod]                     ; from Pod (runs after PodWeaver)
  [ReadmeAnyFromPod / MarkdownInRoot]

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

  [Prereqs]
  [Prereqs / Runtime_Requires]
  -phase        = runtime
  -relationship = requires
  [Prereqs / Runtime_Recommends]
  -phase        = runtime
  -relationship = recommends
  [Prereqs / Test_Requires]
  -phase        = test
  -relationship = requires
  [RemovePrereqs]
  remove = strict
  remove = warnings

  [Authority]
  authority = cpan:SILEX
  do_munging = 0

  [MinimumPerl]       ; determine minimum perl version

  [MetaNoIndex]       ; sets 'no_index' in META
  directory = t
  directory = xt
  directory = examples
  directory = corpus
  directory = public
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

  ; manifest (after all generated files)
  [Manifest]          ; create MANIFEST

  ; copy cpanfile back to repo dis
  [CopyFilesFromBuild]
  copy = cpanfile

  ; before release

  [PromptIfStale]     ; check if our build tools are out of date
  module = Dist::Zilla
  module = Dist::Zilla::PluginBundle::SILEX
  check_all_plugins = 1

  [Git::Check]        ; ensure all files checked in
  allow_dirty = Changes
  allow_dirty = README.mkdn
  allow_dirty = cpanfile
  allow_dirty = dist.ini

  [CheckMetaResources]     ; ensure META has 'resources' data
  [CheckPrereqsIndexed]    ; ensure prereqs are on CPAN
  [CheckChangesHasContent] ; ensure Changes has been updated
  [CheckExtraTests]   ; ensure xt/ tests pass
  [TestRelease]       ; ensure t/ tests pass
  [ConfirmRelease]    ; prompt before uploading

  ; releaser
  [UploadToCPAN]      ; uploads to CPAN

  ; after release
  [Git::Commit / Commit_Dirty_Files] ; commit Changes (as released)
  commit_msg = 'release-%v%n%n%c'

  [Git::Tag]          ; tag repo with custom tag
  tag_format  = release-%v
  tag_message = Release %v

  ; NextRelease acts *during* pre-release to write $VERSION and
  ; timestamp to Changes and  *after* release to add a new {{$NEXT}}
  ; section, so to act at the right time after release, it must actually
  ; come after Commit_Dirty_Files but before Commit_Changes in the
  ; dist.ini.  It will still act during pre-release as usual

  [NextRelease]

  [Git::Commit / Commit_Changes] ; commit Changes (for new dev)

  [Git::Push]         ; push repo to remote
  push_to = origin

=head1 USAGE

To use this PluginBundle, just add it to your dist.ini.  You can provide
the following options:

=over 4

=item *

C<silex_git> — silex local git

=item *

C<is_task> — this indicates whether C<TaskWeaver> or C<PodWeaver> should be used.

Default is 0.

=item *

C<authority> — specifies the C<x_authority> field for pause.  Defaults to 'cpan:SILEX'.

=item *

C<auto_prereq> — this indicates whether C<AutoPrereqs> should be used or not.  Default is 1.

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

C<weaver_config> — specifies a L<Pod::Weaver> bundle.  Defaults to @SILEX.

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

When running without git, C<GatherDir> is used instead of C<Git::GatherDir>,
C<AutoVersion> is used instead of C<Git::NextVersion>, and all git check and
commit operations are disabled.

This PluginBundle now supports C<ConfigSlicer>, so you can pass in options to the
plugins used like this:

  [@SILEX]
  Test::MinimumVersion.max_target_perl = 5.014
  ExecDir.dir = scripts

This PluginBundle also supports C<PluginRemover>, so dropping a plugin is as easy as this:

  [@SILEX]
  -remove = Test::Portability

=for Pod::Coverage configure mvp_multivalue_args

=head1 RELEASE

Release process:

  $ git checkout develop
  $ git rebase origin/develop
  $ dzil test
  $ #
  $ # ... do what you want
  $ #
  $ # now ready to release
  $ #
  $ git checkout master
  $ git rebase origin/master
  $ git merge --no-ff develop
  $ dzil release
  $ git checkout develop
  $ git merge --no-ff master
  $ #
  $ # everything is ok then push
  $ #
  $ git push origin master
  $ git push origin develop

Release with specific version:

  $ #
  $ # ... skip above
  $ #
  $ V=v0.4.55 dzil release
  $ #
  $ # ... skip below
  $ #

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::PluginBundle::DAGOLDEN>

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
at L<https://github.com/silexkr/dist-zilla-pluginbundle-silex/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/silexkr/dist-zilla-pluginbundle-silex>

  git clone https://github.com/silexkr/dist-zilla-pluginbundle-silex.git

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by SILEX.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
