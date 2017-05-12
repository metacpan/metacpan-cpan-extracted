package Dist::Zilla::PluginBundle::BerryGenomics;
use Moose;
use Sub::Install;
use namespace::autoclean;

our $VERSION = '0.3.2'; # VERSION
# ABSTRACT: Dist::Zilla::PluginBundle for BerryGenomics Bioinformatics Department


with 'Dist::Zilla::Role::PluginBundle::Easy';
has installer => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{installer} || 'ModuleBuild' },
);

has exclude_message => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  default =>
  sub { $_[0]->payload->{exclude_message} || '^(Auto|Merge|forgot|typo)' }
);

has max_age => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub {
    $_[0]->payload->{max_age} || 60;
  }
);

has changelog_filename => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    $_[0]->payload->{changelog_filename} || 'Changes';
  }
);

has allow_dirty => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  default => sub {
    my $payload = $_[0]->payload->{allow_dirty};
    if (! $payload) {
      []
    } elsif (ref $payload eq 'ARRAY') {
      $payload
    } else {
      [ $payload ]
    }
  }
);

has commit_msg => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    $_[0]->payload->{commit_msg} || 'Auto commited by dzil with version %v at %d%n%n%c%n';
  }
);

has first_version => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    $_[0]->payload->{first_version} || '0.1.0';
  }
);

has release_branch => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    $_[0]->payload->{release_branch} || 'release/%b';
  }
);

has release_message => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    $_[0]->payload->{release_message} || 'Release %v of %h (on %b)';
  }
);

has version_regexp => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    $_[0]->payload->{version_regexp} || '^v?(\d+\.\d+\.\d+)';
  }
);

has changelog_wrap => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub {
    $_[0]->payload->{changelog_wrap} || '120';
  }
);

has skipped_release_count => (
  is      => 'ro',
  isa     => 'Int',
  default => sub {
    $_[0]->payload->{skipped_release_count} || 2;
  }
);

has debug => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub {
    $_[0]->payload->{debug} || 0;
  }
);


sub configure {
  my $self = shift;

  # Firstly, import plugins from @Basic bundle;
  $self->add_plugins(
    qw(MetaJSON MetaYAML License ExtraTests ExecDir ShareDir Manifest ManifestSkip)
  );

  # Secondly, plugin FakeRelease;
  $self->add_plugins(qw(TestRelease FakeRelease));

  # 3. add installer prereqs
  my @installer_accepts =
    qw( MakeMaker MakeMaker::IncShareDir ModuleBuild ModuleBuildTiny );
  my %accepts = map { $_ => 1 } @installer_accepts;
  unless ($accepts{$self->installer}) {
    die sprintf(
      "Unknown installer: '%s'. "
        . "Acceptable values are MakeMaker, ModuleBuild and ModuleBuildTiny\n",
      $self->installer
    );
  }
  $self->add_plugins($self->installer);

  # 4. some helper plugins
  $self->add_plugins(qw(InstallGuide OurPkgVersion PodWeaver));
  $self->add_plugins(

    # 5. Readme.md
    [ 'ReadmeAnyFromPod',
      {type => 'markdown', filename => 'README.md', location => 'build'}
    ],
    [ 'ReadmeAnyFromPod',
      'MarkdownInRoot',
      { type     => 'markdown',
        filename => 'README.md',
        location => 'root',
        phase    => 'release'
      }
    ],
    ['CopyFilesFromBuild', {copy      => ['LICENSE', $self->changelog_filename]}],
    ['MetaNoIndex',        {directory => [qw(t xt inc share)]}],
  );

  my @dirty_files = ('Changes', 'README.md', 'LICENSE', @{$self->allow_dirty});

  # 6. Git
  $self->add_plugins(
    [ 'Git::GatherDir',
      {exclude_filename => \@dirty_files, include_dotfiles => 1}
    ],
    ['Git::Check', {allow_dirty => \@dirty_files, untracked_files => 'warn'}],
    [ 'Git::Commit',
      { allow_dirty => \@dirty_files,
        commit_msg  => $self->commit_msg
      }
    ],
    [ 'Git::CommitBuild',
      { release_branch  => $self->release_branch,
        release_message => $self->release_message,
      }
    ],
    [ 'Git::Tag',
      {tag_format => '%v', tag_message => 'Release %v'}
    ],
    ['Git::Push', {remotes_must_exist => 0}],
    [ 'Git::NextVersion',
      { first_version     => $self->first_version,
        version_by_branch => 1,
        version_regexp    => $self->version_regexp,
      }
    ],
    [ 'ChangelogFromGit',
      { tag_regexp      => $self->version_regexp,
        max_age         => $self->max_age,
        exclude_message => $self->exclude_message,
        debug           => $self->debug,
        skipped_release_count => $self->skipped_release_count,
        wrap_column           => $self->changelog_wrap,
        file_name             => $self->changelog_filename,
      }
    ],
  );
  $self->add_plugins(['AutoPrereqs']);
}
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::BerryGenomics - Dist::Zilla::PluginBundle for BerryGenomics Bioinformatics Department

=head1 VERSION

version 0.3.2

=head1 SYNOPSIS

in your I<dist.ini>:

  [@BerryGenomics]

Details configration:

  [@BerryGenomics]
  installer = MakeMaker ; default is ModuleBuild
  ; valid installers: MakeMaker MakeMaker::IncShareDir ModuleBuild ModuleBuildTiny

  ; ChangelogFromGit
  changelog_filename = Changes ; file_name in ChangelogFromGit
  changelog_wrap = 74   ; wrap_column in ChangelogFromGit, default 120
  exclude_message = ^(Auto|Merge|Forgot)
  version_regexp = ^v?(\d+\.\d+\.\d+)
  skipped_release_count = 2
  max_age = 365         ; default 60
  debug = 0

  ; Git
  allow_dirty = 'FIle1'
  allow_dirty = 'File2'
  commit_msg  =
  release_branch =
  release_message =

=head1 DESCRIPTION

This is plugin bundle is for BerryGenomics.
It is equivalent to:

  ; Basic
  [MetaJSON]
  [MetaYAML]
  [License]
  [ExtraTests]
  [ExecDir]
  [ShareDir]
  [Manifest]
  [ManifestSkip]

  [TestRelease]
  [FakeRelease]

  ; installer
  [ModuleBuild] ; by default

  ; extra
  [InstallGuide]
  [OurPkgVersion]
  [PodWeaver]
  [ReadmeFromPod]
  [PodSyntaxTests]

  ; with params
  [ReadmeAnyFromPod /MarkdownInRoot]
  filename = Readme.md
  [CopyFilesFromBuild]
  copy = LICENSE
  [MetaNoIndex]
  directory = t
  directory = xt
  directory = inc
  directory = share
  directory = eg
  directory = examples

  ; Git
  [Git::GatherDir]
  exclude_filename = dist.ini
  exclude_filename = Changes
  exclude_filename = README.md
  exclude_filename = LICENSE
  include_dotfiles = 1
  [Git::Check]
  allow_dirty = dist.ini
  allow_dirty = Changes
  allow_dirty = README.md
  allow_dirty = LICENSE
  untracked_files = warn
  [Git::Commit]
  allow_dirty = dist.ini
  allow_dirty = Changes
  allow_dirty = README.md
  allow_dirty = LICENSE
  commit_msg = Auto commited by dzil with version %v at %d%n%n%c%n
  [Git::CommitBuild]
  release_branch = %v
  release_message = Release %v of %h (on %b)
  [Git::Tag]
  tag_format = %v
  tag_message = Auto tagged by dzil release(%v)
  [Git::Push]
  remotes_must_exist = 0
  [Git::NextVersion]
  first_version = 0.0.1
  version_by_branch = 1
  version_regexp = ^v?(\d+(\.\d+){0,2})$
  [ChangelogFromGit::CPAN::Changes]
  tag_regexp = semantic
  group_by_author = 1

  ; run
  [Run::BeforeBuild]
  run = git checkout Changes
  [Run::BeforeRelease]
  run = mkdir -p release 2>/dev/null; cp %n-%v.tar.gz release/ -f

  [AutoPrereqs]

=head1 AUTHOR

Huo Linhe <huolinhe@berrygenomics.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Berry Genomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
