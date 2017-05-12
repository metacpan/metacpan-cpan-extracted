
use strict;
use warnings;
package Dist::Zilla::PluginBundle::HARTZELL;
{
  $Dist::Zilla::PluginBundle::HARTZELL::VERSION = '0.008';
}

# ABSTRACT: My standard dzil config.


use autodie 2.00;
use Moose 0.99;
use namespace::autoclean 0.09;

use Dist::Zilla 4.3; # authordeps

with qw(Dist::Zilla::Role::PluginBundle::Easy
        Dist::Zilla::Role::PluginBundle::Config::Slicer);


sub mvp_multivalue_args { qw/stopwords/ }


has stopwords => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{stopwords} ? $_[0]->payload->{stopwords} : []
  },
);


has fake_release => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{fake_release} },
);


has no_critic => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{no_critic} ? $_[0]->payload->{no_critic} : 0
  },
);


has no_spellcheck => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{no_spellcheck}
         ? $_[0]->payload->{no_spellcheck}
         : 0
  },
);


has is_task => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{is_task} },
);


has use_autoprereqs => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{use_autoprereqs} ? $_[0]->payload->{use_autoprereqs} : 1
  },
);


has tag_format => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{tag_format} ? $_[0]->payload->{tag_format} : 'release-%v',
  },
);


has version_regexp => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{version_regexp} ? $_[0]->payload->{version_regexp} : '^release-(.+)$',
  },
);


has weaver_config => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{weaver_config} || '@HARTZELL' },
);


has git_remote => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{git_remote} ? $_[0]->payload->{git_remote} : 'origin',
  },
);


sub configure {
  my $self = shift;

  my @push_to = ('origin');
  push @push_to, $self->git_remote if $self->git_remote ne 'origin';

  $self->add_plugins(
                     # version number
                     [ 'Git::NextVersion' => { version_regexp => $self->version_regexp } ],

                     # gather and prune
                     # skip things that are also already in the build dir
                     [ 'Git::GatherDir' =>
                       { exclude_filename => [qw/README.pod META.json cpanfile/] }], # core
                     'PruneCruft',         # core
                     'ManifestSkip',       # core

                     # file munging
                     'PkgVersion',
                     ( $self->is_task
                       ?  'TaskWeaver'
                       : [ 'PodWeaver' => { config_plugin => $self->weaver_config } ]
                     ),

                     # generated distribution files
                     'ReadmeFromPod',
                     'License',            # core
                     [ ReadmeAnyFromPod => { # generate in root for github, etc.
                                            type => 'pod',
                                            filename => 'README.pod',
                                            location => 'root',
                                           }
                     ],

                     # generated t/ tests
                     [ 'Test::Compile' => { fake_home => 1 } ],
                     
                     # generated xt/ tests
                     ( $self->no_spellcheck
                       ? ()
                       : [ 'Test::PodSpelling' => { stopwords => $self->stopwords } ] ),
                     'Test::Perl::Critic',
                     'MetaTests',          # core
                     'PodSyntaxTests',     # core
                     'PodCoverageTests',   # core
                     'Test::Portability',
                     'Test::Version',
                     
                     # metadata
                     'MinimumPerl',
                     ( $self->use_autoprereqs
                       ? [ 'AutoPrereqs' => { skip => "^t::lib" } ]
                       : ()
                     ),
                     [ MetaNoIndex => {
                                       directory => [qw/t xt examples corpus/],
                                       'package' => [qw/DB/]
                                      }
                     ],
                     ['MetaProvides::Package' => { meta_noindex => 1 } ], # AFTER MetaNoIndex
                     [ AutoMetaResources => {
                                             'repository.github' => 'user:hartzell',
                                             'bugtracker.github' => 'user:hartzell',
                                             'homepage' => 'https://metacpan.org/release/%{dist}',
                                            }
                     ],

                     'MetaYAML',           # core
                     'MetaJSON',           # core

                     # build system
                     'ExecDir',            # core
                     'ShareDir',           # core
                     'ModuleBuild',          # core

                     # copy files from build back to root for inclusion in VCS
                     [ CopyFilesFromBuild => {
                                              copy => [ qw( cpanfile ) ],
                                             }
                     ],
                     
                     # manifest -- must come after all generated files
                     'Manifest',           # core

                     # before release
                     [ 'Git::Check' =>
                       {
                        allow_dirty => [qw/dist.ini Changes README.pod/]
                       }
                     ],
                     'CheckMetaResources',
                     'CheckPrereqsIndexed',
                     'CheckChangesHasContent',
                     'CheckExtraTests',
                     'TestRelease',        # core
                     'ConfirmRelease',     # core
                     
                     # release
                     ( $self->fake_release ? 'FakeRelease' : 'UploadToCPAN'),       # core

                     # after release
                     # Note -- NextRelease is here to get the ordering right with
                     # git actions.  It is *also* a file munger that acts earlier

                     # commit dirty Changes, dist.ini, README.pod, META.json
                     [ 'Git::Commit' => 'Commit_Dirty_Files' =>
                       {
                        allow_dirty => [qw/dist.ini Changes README.pod/]
                       }
                     ],
                     [ 'Git::Tag' => { tag_format => $self->tag_format } ],
                     
                     # bumps Changes
                     'NextRelease',        # core (also munges files)
                     
                     [ 'Git::Commit' => 'Commit_Changes' => { commit_msg => "bump Changes" } ],
                     
                     [ 'Git::Push' => { push_to => \@push_to } ],
                     
                    );
  
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::HARTZELL - My standard dzil config.

=head1 VERSION

version 0.008

=head1 SYNOPSIS

   # in dist.ini
   [@HARTZELL]

=head1 DESCRIPTION

This, a L<Dist::Zilla> PluginBundle that builds things the way that I
do, is a work in progress.

I left my standard PluginBundle behind when I left my previous job and
I've discovered that I've fallen behind the state of the art.  This is
my attempt to catch back up.  After browsing the bevy of bundles on
CPAN I decided to model mine on DAGOLDEN's (I like his use of
ConfigSlicer and various config options).  As it stands now it's
nearly a copy of his work but as my personal preferences assert
themselves I expect it to diverge.  For now I have a lot of
github and Meta info stuff to catch up on.

In its default form it is roughly equivalent to the following
dist.ini:

   ; version provider
   [Git::NextVersion]  ; get version from last release tag
   version_regexp = ^release-(.+)$
 
   ; choose files to include
   [Git::GatherDir]         ; everything from git ls-files
   exclude_filename = README.pod   ; skip this generated file
   exclude_filename = META.json    ; skip this generated file
   exclude_filename = cpanfile     ; skip this generated file
 
   [PruneCruft]        ; default stuff to skip
   [ManifestSkip]      ; if -f MANIFEST.SKIP, skip those, too
 
   ; file modifications
   [PkgVersion]        ; add $VERSION = ... to all files
   [PodWeaver]         ; generate Pod
   config_plugin = @HARTZELL
 
   ; generated files
   [ReadmeFromPod]     ; from Pod (runs after PodWeaver)
   [License]           ; boilerplate license
   [ReadmeAnyFromPod]  ; create README.md in repo directory
   type = pod          ; this makes github happy....
   filename = README.pod
   location = root
 
   ; t tests
   [Test::Compile]     ; make sure .pm files all compile
   fake_home = 1       ; fakes $ENV{HOME} just in case
 
   ; xt tests
   [Test::PodSpelling] ; xt/author/pod-spell.t
   [Test::Perl::Critic]; xt/author/critic.t
   [MetaTests]         ; xt/release/meta-yaml.t
   [PodSyntaxTests]    ; xt/release/pod-syntax.t
   [PodCoverageTests]  ; xt/release/pod-coverage.t
   [Test::Portability] ; xt/release/portability.t (of file name)
   [Test::Version]     ; xt/release/test-version.t
 
   ; metadata
   [MinimumPerl]       ; determine minimum perl version
   [AutoPrereqs]       ; find prereqs from code
   skip = ^t::lib
   [MetaNoIndex]       ; sets 'no_index' in META
   directory = t
   directory = xt
   directory = examples
   directory = corpus
   package = DB        ; just in case
 
   [MetaProvides::Package] ; add 'provides' to META files
   meta_noindex = 1        ; respect prior no_index directives
 
   [AutoMetaResources] ; set META resources
   bugtracker.github  = user:hartzell
   repository.github  = user:hartzell
   homepage           = https://metacpan.org/release/%{dist}
 
   [MetaYAML]          ; generate META.yml (v1.4)
   [MetaJSON]          ; generate META.json (v2)
 
   ; build system
   [ExecDir]           ; include 'bin/*' as executables
   [ShareDir]          ; include 'share/' for File::ShareDir
   [Module::Build]     ; create Build.PL
 
   ; copy META.json back to repo dis
   [CopyFilesFromBuild]
   copy = cpanfile
 
   ; manifest (after all generated files)
   [Manifest]          ; create MANIFEST
 
   ; before release
   [Git::Check]        ; ensure all files checked in
   allow_dirty = dist.ini
   allow_dirty = Changes
   allow_dirty = README.pod
 
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
   allow_dirty = dist.ini
   allow_dirty = Changes
   allow_dirty = README.pod
 
   [Git::Tag]          ; tag repo with custom tag
   tag_format = release-%v
 
   ; NextRelease acts *during* pre-release to write $VERSION and
   ; timestamp to Changes and  *after* release to add a new {{$NEXT}}
   ; section, so to act at the right time after release, it must actually
   ; come after Commit_Dirty_Files but before Commit_Changes in the
   ; dist.ini.  It will still act during pre-release as usual
 
   [NextRelease]
 
   [Git::Commit / Commit_Changes] ; commit Changes (for new dev)
   commit_msg = bump Changes
 
   [Git::Push]         ; push repo to remote
   push_to = origin

=head2 Usage

To use this PluginBundle, just add it to your dist.ini.  See the
L</ATTRIBUTES> section for user configurable options.

This PluginBundle supports ConfigSlicer, so you can pass in options to
individual plugins directly if necessary.

   [@HARTZELL]
   ExecDir.dir = scripts ; overrides ExecDir's dir option

=head1 ATTRIBUTES

=head2 stopwords

Moose ArrayRef attribute that keeps track of a list of stopwords for
various spelling tasks.  Defaults to an empty list, controlled by
'stopwords' lines in the dist.ini.  There can be multiple stopwords
lines in the dist.ini file.

Do this:

  stopwords = one two three
  stopwords = some more words

to build up your own list of stopwords.

=head2 fake_release

Moose boolean attribute, when set to true the bundle swaps the
FakeRelease plugin in place of the UploadToCPAN plugin. Mostly useful
for testing a dist.ini without risking a real release.  Defaults to
false, controlled by the value of the 'fake_release' dist.ini option.

Do this:

  fake_release = 1

to do a fake release.  

=head2 no_critic

Moose boolean attribute, when set to true it disables the Perl::Critic
tests.  Defaults to false, controlled by the value of the 'no_critic'
dist.ini option.

Do this:

  no_critic = 1

to do disable critic testing.

=head2 no_spellcheck

Moose boolean attribute, when set to true it disables the
Test::PodSpelling tests.  Defaults to false, controlled by the value
of the 'no_spellcheck' dist.ini option.

Do this:

  no_spellcheck = 1

to do disable spell checking.

=head2 is_task

Moose boolean attribute, when set to true it loads TaskWeaver instead
of PodWeaver.  Defaults to false, controlled by the value of the
'is_task' dist.ini option.

Do this:

  is_task = 1

to build a Task:: distribution.

=head2 use_autoprereqs

Moose boolean attribute, when set to true it loads the AutoPrereqs
plugin.  Defaults to true, controlled by the value of the
'use_autoprereqs' dist.ini option.

Do this:

  use_autoprereqs = 0

to do disable AutoPrereqs.

=head2 tag_format

Moose Str attribute, defines the format used by Git::Tag.  Defaults to
'release-%v', controlled by the value of the 'tag_format' dist.ini option.

Do this:

  tag_format = my-release-%v

to set it to something other than the default.

=head2 version_regexp

Moose Str attribute, defines the regexp that Git::NextVersion uses to
figure out the current version.  Defaults to '^release-(.+)$' and is
controlled by the value of the 'version_regexp' dist.ini option.

Do this:

  version_regexp = ^my-release-(.+)$

to set it to something other than the default.

=head2 weaver_config

Moose Str attribute, controls the name of the PodWeaver configuration.
Defaults to '@HARTZELL', controlled by the value of the 'weaver_config'
dist.ini option.

Do this:

  weaver_config = @DAGOLDEN

to e.g. use Pod::Weaver::PluginBundle::DAGOLDEN.

=head2 git_remote

Moose Str attribute, controls the name of the git remote.  Defaults to
'origin', controlled by the value of the 'git_remote' dist.ini option.

Do this:

  git_remote = 'something_else'

to use something other than the default.

=head1 METHODS

=head2 mvp_multivalue_args

Returns the list of the dist.ini options that can take multiple
values.  Currently returns qw/stopwords/.

=head2 configure

Does the heavy lifting, adds the plugins, etc....

=head1 COMMON PATTERNS

=head2 nothing much to see here for now....

   [@HARTZELL]
   fakerelease = 1

=head1 SEE ALSO

=over

=item *

L<Dist::Zilla>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=item *

L<Dist::Zilla::Plugin::TaskWeaver>

=item *

L<Dist::Zilla::PluginBundle::ConfigSlicer>

=back

=head1 AUTHORS

=over 4

=item *

George Hartzell <hartzell@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by George Hartzell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
