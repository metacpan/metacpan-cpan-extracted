use strict;
use warnings;
package Dist::Zilla::PluginBundle::MITHALDU;
our $VERSION = '1.172230'; # VERSION

# Dependencies
use autodie 2.00;
use Moose 0.99;
use Moose::Autobox;
use namespace::autoclean 0.09;
use CPAN::Meta;
use Try::Tiny;

use Dist::Zilla 4.3; # authordeps

use Dist::Zilla::PluginBundle::Filter ();
use Dist::Zilla::PluginBundle::Git ();

use Dist::Zilla::Plugin::AutoVersion ();
use Dist::Zilla::Plugin::Bugtracker 1.102670 ();
use Dist::Zilla::Plugin::CheckChangesHasContent ();
use Dist::Zilla::Plugin::CheckExtraTests ();
use Dist::Zilla::Plugin::CheckPrereqsIndexed 0.002 ();
use Dist::Zilla::Plugin::Test::Compile ();
use Dist::Zilla::Plugin::CopyFilesFromBuild ();
use Dist::Zilla::Plugin::GithubMeta 0.10 ();
use Dist::Zilla::Plugin::InsertCopyright 0.001 ();
use Dist::Zilla::Plugin::MetaNoIndex ();
use Dist::Zilla::Plugin::MetaProvides::Package 1.11044404 ();
use Dist::Zilla::Plugin::MinimumPerl ();
use Dist::Zilla::Plugin::OurPkgVersion 0.001008 ();
use Dist::Zilla::Plugin::Test::Perl::Critic ();
use Dist::Zilla::Plugin::PodWeaver ();
use Dist::Zilla::Plugin::Test::Portability ();
use Dist::Zilla::Plugin::ReadmeAnyFromPod 0.120051 ();
use Dist::Zilla::Plugin::ReadmeFromPod ();
use Dist::Zilla::Plugin::StaticVersion ();
use Dist::Zilla::Plugin::TaskWeaver 0.101620 ();
use Dist::Zilla::Plugin::Test::Version ();

use Dist::Zilla::PluginBundle::MITHALDU::Templates;
use Dist::Zilla::Util::FileGenerator;

use Dist::Zilla::App::Command::cover; # this is just here for the prereqs to
                                      # ensure it's available for dev

with 'Dist::Zilla::Role::PluginBundle::Easy';

sub mvp_multivalue_args { qw/gitignore exclude_match skip_prereq/ }

has fake_release => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{fake_release} },
);

has no_critic => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
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
    exists $_[0]->payload->{auto_prereq} ? $_[0]->payload->{auto_prereq} : 1
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

has weaver_config => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{weaver_config} || '@MITHALDU' },
);

has git_remote => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{git_remote} ? $_[0]->payload->{git_remote} : 'origin',
  },
);

has major_version => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{major_version} ? $_[0]->payload->{major_version} : 1
  },
);

has gitignore => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{gitignore} ? $_[0]->payload->{gitignore} : []
  },
);

has exclude_match => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  default => sub {
    my ($self) = @_;
    my $payload = $_[0]->payload;
    return [] if !exists $payload->{exclude_match};
    my $match = $payload->{exclude_match};
    return ref $match ? $match : [$match];
  },
);

has skip_prereq => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  default => sub {
    my ($self) = @_;
    my $payload = $_[0]->payload;
    return [] if !exists $payload->{skip_prereq};
    my $match = $payload->{skip_prereq};
    return ref $match ? $match : [$match];
  },
);

has prune_except => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{prune_except} ? $_[0]->payload->{prune_except} : []
  },
);

sub old_meta {
  my $meta = try {
    CPAN::Meta->load_file("META.json");
  }
  catch {
    warn "META.json could not be read, using fallback meta. Error:\n $_";
    return { version => 0.1, resources => { homepage => 'http://homepage', repository => { web => "user/repo" } } };
  };

  my @github_url = split '/', $meta->{resources}{repository}{web};
  my ( $old_repo, $old_user ) = ( pop @github_url, pop @github_url );
  my $github = [ homepage => $meta->{resources}{homepage}, repo => $old_repo, user => $old_user ];

  my $version = $meta->{version};

  return ( $version, $github, $meta );
}

sub configure {
  my $self = shift;

  my @push_to = ('origin');
  push @push_to, $self->git_remote if $self->git_remote ne 'origin';

  my $gitignore_extra = join "\n", $self->gitignore->flatten;

  my $gen = Dist::Zilla::Util::FileGenerator->new(
    files => [
      [ '.gitignore' => ( extra_content => $gitignore_extra, move => 1 ) ],
      'README.PATCHING',
      'perlcritic.rc',
    ],
    source => "Dist::Zilla::PluginBundle::MITHALDU::Templates",
  );

  my ( $old_version, $old_github, $meta ) = $self->old_meta;

  my $version_provider = ['StaticVersion' => { version => $old_version } ];

  my $is_release = grep /^release$/, @ARGV;
  $version_provider = [ 'AutoVersion' => { major => $self->major_version } ] if $is_release;

  my @generated_files = qw( META.json Makefile.PL cpanfile README.pod );
  my @on_release_files = ( qw/dist.ini Changes/, @generated_files );
  my @exclude_match = ( '^' . $meta->{name} . '-', @{$self->exclude_match} );

  my @plugins = (

  # version number
    $version_provider,

  # gather and prune
    [ GatherDir => {
      exclude_filename => [@generated_files],
      exclude_match => \@exclude_match}
    ], # core
    ['PruneCruft', { except => $self->prune_except }], # core
    'ManifestSkip',       # core

  # file munging
    'OurPkgVersion',
    'Git::Contributors',
    'InsertCopyright',
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
    'Test::Perl::Critic',
    'MetaTests',          # core
    'PodSyntaxTests',     # core
    'PodCoverageTests',   # core
    'Test::Portability',
    'Test::Version',

  # metadata
    'MinimumPerl',
    ( $self->auto_prereq ? ['AutoPrereqs' => (scalar @{$self->skip_prereq}) ? ({ skip => $self->skip_prereq }) : ()] : () ),
    'CPANFile',
    [ GithubMeta => { remote => $self->git_remote, ( $is_release ? () : @{$old_github} ), issues => 1 } ],
    [ MetaNoIndex => {
        directory => [qw/t xt examples corpus/],
        'package' => [qw/DB/]
      }
    ],
    ['MetaProvides::Package' => { meta_noindex => 1 } ], # AFTER MetaNoIndex
    'MetaYAML',           # core
    'MetaJSON',           # core

  # build system
    'ExecDir',            # core
    'ShareDir',           # core
    'MakeMaker',          # core

  # copy files from build back to root for inclusion in VCS
  [ CopyFilesFromBuild => {
      copy => \@generated_files
    }
  ],

  # manifest -- must come after all generated files
    'Manifest',           # core

  # before release
    [ 'Git::Check' =>
      {
        allow_dirty => [@on_release_files]
      }
    ],
    'CheckPrereqsIndexed',
    'CheckChangesHasContent',
    'CheckExtraTests',
    'TestRelease',        # core
    'ConfirmRelease',     # core

  # release
    ( $self->fake_release ? 'FakeRelease' : 'UploadToCPAN'),       # core

  # after release
    'NextRelease',        # core (also munges files)

    # commit dirty Changes, dist.ini, README.pod, META.json
    [ 'Git::Commit' =>
      {
        allow_dirty => [@on_release_files]
      }
    ],
    [ 'Git::Tag' => { tag_format => $self->tag_format } ],

    [ 'Git::Push' => { push_to => \@push_to } ],

  );

  @plugins = $gen->combine_with( @plugins );

  $self->add_plugins( @plugins );

}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Dist::Zilla configuration the way MITHALDU does it
#
# This file is part of Dist-Zilla-PluginBundle-MITHALDU
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::MITHALDU - Dist::Zilla configuration the way MITHALDU does it

=head1 VERSION

version 1.172230

=head1 SYNOPSIS

   # in dist.ini
   [@MITHALDU]

=head1 DESCRIPTION

This module is forked off of L<Dist::Zilla::PluginBundle::DAGOLDEN> and modified
to suit my own tastes. He did most of the work.

This is a L<Dist::Zilla> PluginBundle.  It is roughly equivalent to the
following dist.ini:

   ; version provider
   [AutoVersion]  ; build a version from the date
   major = 1
 
   ; choose files to include
   [GatherDir]         ; everything under top dir
   exclude_filename = README.pod   ; skip this generated file
   exclude_filename = META.json    ; skip this generated file
   exclude_filename = .gitignore   ; skip this generated file
   exclude_filename = README.PATCHING ; skip this generated file
   exclude_filename = perlcritic.rc   ; skip this generated file
 
   [PruneCruft]        ; default stuff to skip
   except = .gitignore
   except = README.PATCHING
   except = perlcritic.rc
   [ManifestSkip]      ; if -f MANIFEST.SKIP, skip those, too
 
   ; file modifications
   [OurPkgVersion]     ; add $VERSION = ... to all files
   [InsertCopyright    ; add copyright at "# COPYRIGHT"
   [PodWeaver]         ; generate Pod
   config_plugin = @MITHALDU ; my own plugin allows Pod::WikiDoc
 
   ; generated files
   [License]           ; boilerplate license
   [ReadmeFromPod]     ; from Pod (runs after PodWeaver)
   [ReadmeAnyFromPod]  ; create README.pod in repo directory
   type = pod
   filename = README.pod
   location = root
   [GenerateFile]
   filename    = .gitignore
   is_template = 1
   content = /.build
   content = /{{ $dist->name }}-*
   ; and more, see Dist::Zilla::PluginBundle::MITHALDU::Templates
   [GenerateFile]
   filename    = README.PATCHING
   is_template = 1
   content = README.PATCHING
   ; and more, see Dist::Zilla::PluginBundle::MITHALDU::Templates
   [GenerateFile]
   filename    = perlcritic.rc
   is_template = 1
   content = README.PATCHING
   ; and more, see Dist::Zilla::PluginBundle::MITHALDU::Templates
 
   ; t tests
   [Test::Compile]     ; make sure .pm files all compile
   fake_home = 1       ; fakes $ENV{HOME} just in case
 
   ; xt tests
   [Test::Perl::Critic]; xt/author/critic.t
   [MetaTests]         ; xt/release/meta-yaml.t
   [PodSyntaxTests]    ; xt/release/pod-syntax.t
   [PodCoverageTests]  ; xt/release/pod-coverage.t
   [Test::Portability] ; xt/release/portability.t (of file name)
   [Test::Version]     ; xt/release/test-version.t
 
   ; metadata
   [AutoPrereqs]       ; find prereqs from code
   [MinimumPerl]       ; determine minimum perl version
   [GithubMeta]
 
   [MetaNoIndex]       ; sets 'no_index' in META
   directory = t
   directory = xt
   directory = examples
   directory = corpus
   package = DB        ; just in case
 
   [Bugtracker]        ; defaults to RT
 
   [MetaProvides::Package] ; add 'provides' to META files
   meta_noindex = 1        ; respect prior no_index directives
 
   [MetaYAML]          ; generate META.yml (v1.4)
   [MetaJSON]          ; generate META.json (v2)
 
   ; build system
   [ExecDir]           ; include 'bin/*' as executables
   [ShareDir]          ; include 'share/' for File::ShareDir
   [MakeMaker]         ; create Makefile.PL
 
   ; manifest (after all generated files)
   [Manifest]          ; create MANIFEST
 
   ; copy META.json back to repo dis
   [CopyFilesFromBuild]
   copy = META.json
   move = .gitignore
   copy = README.PATCHING
   copy = perlcritic.rc
 
   ; before release
   [Git::Check]        ; ensure all files checked in
   allow_dirty = dist.ini
   allow_dirty = Changes
   allow_dirty = README.pod
   allow_dirty = META.json
 
   [CheckPrereqsIndexed]    ; ensure prereqs are on CPAN
   [CheckChangesHasContent] ; ensure Changes has been updated
   [CheckExtraTests]   ; ensure xt/ tests pass
   [TestRelease]       ; ensure t/ tests pass
   [ConfirmRelease]    ; prompt before uploading
 
   ; releaser
   [UploadToCPAN]      ; uploads to CPAN
 
   ; after release
   [NextRelease]
 
   [Git::Commit] ; commit Changes (as released)
   allow_dirty = dist.ini
   allow_dirty = Changes
   allow_dirty = README.pod
   allow_dirty = META.json
 
   [Git::Tag]          ; tag repo with custom tag
   tag_format = release-%v
 
   [Git::Push]         ; push repo to remote
   push_to = origin

=for Pod::Coverage configure mvp_multivalue_args old_meta

=head1 USAGE

To use this PluginBundle, just add it to your dist.ini.  You can provide
the following options:

=over

=item *

C<<< is_task >>> -- this indicates whether TaskWeaver or PodWeaver should be used.
Default is 0.

=item *

C<<< auto_prereq >>> -- this indicates whether AutoPrereq should be used or not.
Default is 1.

=item *

C<<< tag_format >>> -- given to C<<< Git::Tag >>>.  Default is 'release-%v' to be more
robust than just the version number when parsing versions

=item *

C<<< major_version >>> -- overrides the major version set by AutoVersion

=item *

C<<< fake_release >>> -- swaps FakeRelease for UploadToCPAN. Mostly useful for
testing a dist.ini without risking a real release.

=item *

C<<< weaver_config >>> -- specifies a Pod::Weaver bundle.  Defaults to @MITHALDU.

=item *

C<<< no_critic >>> -- omit Test::Perl::Critic tests

=item *

C<<< gitignore >>> -- adds entries to be added to .gitignore (can be repeated)

=item *

C<<< exclude_match >>> -- regexes to exclude files from the dist (can be repeated)

=item *

C<<< prune_except >>> -- regexes to except files from being pruned as cruft (can
be repeated)

=back

=head1 SEE ALSO

=over

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
at L<https://github.com/wchristian/dist-zilla-pluginbundle-mithaldu/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/dist-zilla-pluginbundle-mithaldu>

  git clone https://github.com/wchristian/dist-zilla-pluginbundle-mithaldu.git

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 CONTRIBUTOR

=for stopwords David Golden

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
