package Dist::Zilla::PluginBundle::Author::GETTY;
# ABSTRACT: BeLike::GETTY when you build your dists
our $VERSION = '0.315';
use Moose;
use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';

# Defaults published for any [@Author::GETTY::Docker / ...] subsections that
# appear after [@Author::GETTY] in dist.ini. The subsection bundle reads from
# here when no explicit value is set on the subsection itself.
our %DOCKER_DEFAULTS;

sub bundle_config {
  my ($class, $section) = @_;

  my $self = $class->new($section);

  %DOCKER_DEFAULTS = (
    image => $self->payload->{docker_image},
    tags  => $self->payload->{docker_tags},
    local => $self->payload->{docker_local},
  );

  $self->configure;

  return $self->plugins->@*;
}


use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::PluginBundle::Git;
use Dist::Zilla::PluginBundle::Git::VersionManager;

has manual_version => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{manual_version} },
);

has major_version => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub { $_[0]->payload->{version} || 0 },
);

has author => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{author} || 'GETTY' },
);

has authority => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return 'cpan:'.$self->payload->{authority} if $self->payload->{authority};
    return 'cpan:'.$self->author;
  },
);

has installrelease_command => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{installrelease_command} || 'cpanm .' },
);

has no_installrelease => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{no_installrelease} },
);

has release_branch => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{release_branch} || 'main' },
);

has deprecated => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{deprecated} },
);

has no_github => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return $self->payload->{no_github} if defined $self->payload->{no_github};
    return $self->_has_github_remote ? 0 : 1;
  },
);

has no_github_release => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return $self->payload->{no_github_release} if defined $self->payload->{no_github_release};
    return $self->_has_github_remote ? 0 : 1;
  },
);

# Look at .git/config (relative to the cwd, which dzil sets to the dist root)
# and return true if any remote URL points at github.com. Used to auto-disable
# the GitHub-specific plugins when the dist lives somewhere else (GitLab,
# Codeberg, a private Gitea, no remote at all, ...).
has _has_github_remote => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub {
    my $config = '.git/config';
    return 0 unless -e $config;
    open my $fh, '<', $config or return 0;
    while (my $line = <$fh>) {
      if ($line =~ m{^\s*url\s*=.*\bgithub\.com\b}i) {
        close $fh;
        return 1;
      }
    }
    close $fh;
    return 0;
  },
);

has no_cpan => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{no_cpan} },
);

has no_changes => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{no_changes} },
);

has commit_files_after_release => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { defined $_[0]->payload->{commit_files_after_release} ? $_[0]->payload->{commit_files_after_release} : [] },
);

has no_install => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{no_install} },
);

has no_makemaker => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { ($_[0]->payload->{no_makemaker} || $_[0]->is_alien || $_[0]->xs || $_[0]->xs_alien) ? 1 : 0 },
);

has alien_build => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{alien_build} },
);

has no_podweaver => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{no_podweaver} },
);

has include_readme => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{include_readme} },
);

has xs => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{xs} },
);

has is_task => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{task} },
);

has is_alien => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->alien_repo ? 1 : 0 },
);

has weaver_config => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{weaver_config} || '@Author::GETTY' },
);

has irc => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{irc} || '' },
);

has irc_server => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{irc_server} || 'irc.perl.org' },
);

has irc_user => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return $self->payload->{irc_user} if $self->payload->{irc_user};
    return 'Getty' if $self->author eq 'GETTY';
    return '';
  },
);

has adoptme => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{adoptme} },
);

has xs_alien => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{xs_alien} || '' },
);

has xs_object => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{xs_object} || '' },
);

has version_finder => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { defined $_[0]->payload->{version_finder} ? $_[0]->payload->{version_finder} : [] },
);


my @gather_array_options = qw( exclude_filename exclude_match );
my @gather_array_attributes = map { 'gather_'.$_ } @gather_array_options;

for my $attr (@gather_array_attributes) {
  has $attr => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { defined $_[0]->payload->{$attr} ? $_[0]->payload->{$attr} : [] },
  );
}

has gather_include_dotfiles => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { exists $_[0]->payload->{gather_include_dotfiles} ? $_[0]->payload->{gather_include_dotfiles} : 1 },
);

has gather_include_untracked  => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{gather_include_untracked} },
);

my @run_options = qw( after_build before_build before_release release after_release test );
my @run_ways = qw( run run_if_trial run_no_trial run_if_release run_no_release );

my @run_attributes = map { my $o = $_; map { join('_',$_,$o) } @run_ways } @run_options;

for my $attr (@run_attributes) {
  has $attr => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { defined $_[0]->payload->{$attr} ? $_[0]->payload->{$attr} : [] },
  );
}

my @alien_options = qw( msys repo name bins pattern_prefix pattern_suffix pattern_version pattern autoconf_with_pic isolate_dynamic version_check );
my @alien_array_options = qw( build_command install_command test_command );

my @alien_attributes = map { 'alien_'.$_ } @alien_options;
my @alien_array_attributes = map { 'alien_'.$_ } @alien_array_options;

for my $attr (@alien_attributes) {
  has $attr => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { defined $_[0]->payload->{$attr} ? $_[0]->payload->{$attr} : "" },
  );
}

for my $attr (@alien_array_attributes) {
  has $attr => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { defined $_[0]->payload->{$attr} ? $_[0]->payload->{$attr} : [] },
  );
}

has alien_bin_requires => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { defined $_[0]->payload->{alien_bin_requires} ? $_[0]->payload->{alien_bin_requires} : [] },
);

sub mvp_multivalue_args { @run_attributes, @gather_array_attributes, 'alien_bin_requires', @alien_array_attributes, 'commit_files_after_release', 'version_finder' }

sub effective_gather_exclude_filename {
  my ($self) = @_;

  my @exclude = @{ $self->gather_exclude_filename };
  push @exclude, 'README.md' unless $self->include_readme;

  my %seen;
  return [ grep { !$seen{$_}++ } @exclude ];
}

sub configure {
  my ($self) = @_;

  $self->log_fatal("you must not specify both weaver_config and is_task")
    if $self->is_task and $self->weaver_config ne '@Author::GETTY';

  $self->log_fatal("you must not specify both author and no_cpan")
    if $self->no_cpan and $self->author ne 'GETTY';

  $self->log_fatal("no_install can't be used together with no_makemaker")
    if $self->no_install and $self->no_makemaker;

  $self->add_plugins([ 'Git::GatherDir' => {
    include_dotfiles => $self->gather_include_dotfiles,
    include_untracked => $self->gather_include_untracked,
    scalar @{ $self->effective_gather_exclude_filename } > 0 ? ( exclude_filename => $self->effective_gather_exclude_filename ) : (),
    scalar @{$self->gather_exclude_match} > 0 ? ( exclude_match => $self->gather_exclude_match ) : (),
  }]);

  my @removes = ('GatherDir','PruneCruft');
  if ($self->no_cpan || $self->no_makemaker) {
    push @removes, 'UploadToCPAN' if $self->no_cpan;
    push @removes, 'MakeMaker' if $self->no_makemaker;
  }
  $self->add_bundle('Filter' => {
    -bundle => '@Basic',
    -remove => [@removes],
  });

  if ($self->no_install) {
    $self->add_plugins('MakeMaker::SkipInstall');
  }

  if ($self->xs) {
    $self->add_plugins(qw(
      ModuleBuildTiny
    ));
  }

  if ($self->alien_build) {
    $self->add_plugins('AlienBuild');
  }

  if ($self->xs_alien) {
    my $alien = $self->xs_alien;
    # Get the XS object name from xs_object or derive from alien name
    my $xs_object = $self->xs_object;
    unless ($xs_object) {
      # Derive from Alien module name (e.g., Alien::TinyCDB -> TinyCDB)
      $xs_object = $alien;
      $xs_object =~ s/.*:://;
    }
    $self->add_plugins([
      'MakeMaker::Awesome' => {
        header => "use $alien;",
        WriteMakefile_arg => [
          "LIBS => [ $alien->libs ]",
          "INC => $alien->cflags",
          "OBJECT => '${xs_object}\$(OBJ_EXT)'",
        ],
      }
    ]);
  }

  if ($self->deprecated) {
    $self->add_plugins(qw(
      Deprecated
    ));
  }

  unless ($self->manual_version) {
    if ($self->is_task) {
      my $v_format = q<{{cldr('yyyyMMdd')}}>
                   . sprintf('.%03u', ($ENV{N} || 0));

      $self->add_plugins([
        AutoVersion => {
          major     => $self->major_version,
          format    => $v_format,
        }
      ]);
    }
    # Git::VersionManager handles versioning for non-task distributions
  }

  for (@run_options) {
    my $net = $_;
    my $func = 'run_'.$_;
    if (@{$self->$func}) {
      my $plugin = join('',map { ucfirst($_) } split(/_/,$_));
      $self->add_plugins([
        'Run::'.$plugin => {
          run => $self->$func,
        }
      ]);
    }
  }

  # PkgVersion only when NOT using @Git::VersionManager (which uses RewriteVersion)
  if ($self->is_task || $self->manual_version) {
    $self->add_plugins(
      @{ $self->version_finder }
        ? [ 'PkgVersion' => { finder => $self->version_finder } ]
        : 'PkgVersion'
    );
  }

  $self->add_plugins(qw(
    MetaConfig
    MetaJSON
    PodSyntaxTests
    Test::ChangesHasContent
  ));

  $self->add_plugins([
    'MetaProvides::Package' => {
      inherit_version => 1,
      inherit_missing => 1,
      meta_noindex    => 1,
    }
  ]);

  $self->add_plugins($self->no_github ? 'Repository' : [ 'GithubMeta' => { issues => 1 } ]);

  # Add IRC metadata if configured
  if ($self->irc) {
    my $channel = $self->irc;
    $channel = '#' . $channel unless $channel =~ /^#/;
    my $irc_url = 'irc://' . $self->irc_server . '/' . $channel;
    my %irc_resources = ( 'x_IRC' => $irc_url );
    $irc_resources{'x_IRC_user'} = $self->irc_user if $self->irc_user;
    $self->add_plugins([
      'MetaResources' => \%irc_resources
    ]);
  }

  # Add adoptme metadata if configured
  if ($self->adoptme) {
    $self->add_plugins([
      'MetaResources' => 'adoptme' => { 'x_adoptme' => 1 }
    ]);
  }

  if ($self->is_alien) {
    my %alien_values;
    for (@alien_options) {
      my $func = 'alien_'.$_;
      $alien_values{$_} = $self->$func if defined $self->$func && $self->$func ne '';
    }
    for (@alien_array_options) {
      my $func = 'alien_'.$_;
      $alien_values{$_} = $self->$func if @{ $self->$func };
    }
    if(@{ $self->alien_bin_requires }) {
      $alien_values{bin_requires} = $self->alien_bin_requires;
    }
    $self->add_plugins([
      'Alien' => \%alien_values,
    ]);
  }

  unless ($self->no_installrelease || $self->is_alien) {
    $self->add_plugins([
      'InstallRelease' => {
        install_command => $self->installrelease_command,
      }
    ]);
  }

  unless (!$self->is_alien || $self->no_installrelease) {
    $self->add_plugins([
      'Run::Test' => 'AlienInstallTestHack' => {
        run_if_release => ['./Build install'],
      },
    ]);
  }

  unless ($self->no_cpan) {
    $self->add_plugins([
      'Authority' => {
        ':version'  => '1.009',
        authority   => $self->authority,
        do_munging  => 0,
        do_metadata => 1,
      }
    ]);
  }

  $self->add_plugins([
    'Git::CheckFor::CorrectBranch' => {
      release_branch => $self->release_branch,
    },
  ]);

  $self->add_plugins('Prereqs::FromCPANfile');

  # NextRelease is handled by @Git::VersionManager

  if ($self->is_task) {
    $self->add_plugins('TaskWeaver');
  } else {
    unless ($self->no_podweaver) {
      $self->add_plugins([
        PodWeaver => { config_plugin => $self->weaver_config }
      ]);
    }
  }

  unless ($self->is_task || $self->manual_version) {
    $self->add_bundle('@Git::VersionManager' => {
      'RewriteVersion::Transitional.fallback_version_provider' => 'Git::NextVersion',
      'Git::Tag.tag_format' => '%v',
      $self->no_changes ? ( 'NextRelease.format' => '' ) : (),
      @{ $self->commit_files_after_release } ? ( commit_files_after_release => $self->commit_files_after_release ) : (),
      @{ $self->version_finder } ? (
        'RewriteVersion::Transitional.finder' => $self->version_finder,
        'BumpVersionAfterRelease.finder'      => $self->version_finder,
      ) : (),
    });
    $self->add_plugins([
      'Git::Push' => { push_to => 'origin' }
    ]);
  } else {
    $self->add_bundle('@Git' => {
      tag_format => '%v',
      push_to    => [ qw(origin) ],
    });
  }

  unless ($self->no_github || $self->no_github_release) {
    $self->add_plugins([
      'GitHub::CreateRelease' => {
        branch     => $self->release_branch,
        notes_from => 'ChangeLog',
      }
    ]);
  }

  # Docker support: if docker_image is set on this bundle, auto-add a single
  # default [@Author::GETTY::Docker] subsection so the dist has a working
  # Releaser without any extra config. Users who want multiple targets via
  # explicit [@Author::GETTY::Docker / name] subsections can opt out with
  # docker_default = 0 to suppress the auto-default.
  if (defined $self->payload->{docker_image}
      && length $self->payload->{docker_image}
      && ($self->payload->{docker_default} // 1)) {
    $self->add_bundle('@Author::GETTY::Docker' => {});
  }
}

__PACKAGE__->meta->make_immutable;

no Moose;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::GETTY - BeLike::GETTY when you build your dists

=head1 VERSION

version 0.315

=head1 SYNOPSIS

  name    = Your-App
  author  = You User <you@universe.org>
  license = Perl_5
  copyright_holder = You User
  copyright_year   = 2013

  [@Author::GETTY]
  author = YOUONCPAN

=head1 DESCRIPTION

This is the plugin bundle that GETTY uses. You can configure it (given values
are default):

  [@Author::GETTY]
  author = GETTY
  authority = ; optional, overrides author
  deprecated = 0
  release_branch = main
  weaver_config = @Author::GETTY
  no_cpan = 0
  no_install = 0
  no_makemaker = 0
  no_installrelease = 0
  no_changes = 0
  no_podweaver = 0
  include_readme = 0
  xs = 0
  xs_alien = ; e.g. Alien::TinyCDB for XS with Alien
  installrelease_command = cpanm .

In default configuration it is equivalent to:

  [@Filter]
  -bundle = @Basic
  -remove = GatherDir
  -remove = PruneCruft

  [PkgVersion]
  [MetaConfig]
  [MetaJSON]
  [MetaProvides::Package]
  inherit_version = 1
  inherit_missing = 1
  meta_noindex    = 1
  [PodSyntaxTests]
  [GithubMeta]

  [InstallRelease]
  install_command = cpanm .

  [Authority]
  :version = 1.009
  authority = cpan:GETTY ; or cpan:$authority if set
  do_munging = 0
  do_metadata = 1

  [PodWeaver]
  config_plugin = @Author::GETTY

  [Repository]

  [Git::CheckFor::CorrectBranch]
  release_branch = main

  [@Git::VersionManager]
  ; handles versioning, changelog (NextRelease), commits, tags, and push

  [GitHub::CreateRelease]
  branch     = main
  notes_from = ChangeLog
  ; notes_file defaults to "Changes" when notes_from = ChangeLog

If the C<task> argument is given to the bundle, PodWeaver is replaced with
TaskWeaver and AutoVersion is used for versioning (instead of
@Git::VersionManager). You can also give a bigger major version with C<version>:

  [@Author::GETTY]
  task = 1

If the C<manual_version> argument is given, AutoVersion and Git::NextVersion
are omitted.

  [@Author::GETTY]
  manual_version = 1.222333

You can also use shortcuts for integrating L<Dist::Zilla::Plugin::Run>:

  [@Author::GETTY]
  run_after_build = script/do_this.pl --dir %s --version %s
  run_before_build = script/do_this.pl --version %s
  run_before_release = script/myapp_before1.pl %s
  run_release = deployer.pl --dir %d --tgz %a --name %n --version %v
  run_after_release = script/myapp_after.pl --archive %s --version %s
  run_test = script/tester.pl --name %n --version %v some_file.ext
  run_if_release_test = ./Build install
  run_if_release_test = make install

You can also use add up configuration for L<Dist::Zilla::Plugin::Git::GatherDir>,
excluding I<root> or I<prefix>:

  [@Author::GETTY]
  include_readme = 1 # README.md is excluded by default
  gather_include_dotfiles = 1 # activated by default
  gather_include_untracked = 0
  gather_exclude_filename = dir/skip
  gather_exclude_match = ^local_

It also combines on request with L<Dist::Zilla::Plugin::Alien>, you can set
all parameter of the Alien plugin here, just by preceeding with I<alien_>, the
only required parameter here is C<alien_repo>:

  [@Author::GETTY]
  alien_repo = http://myapp.org/releases
  alien_bins = myapp myapp_helper
  alien_name = myapp
  alien_pattern_prefix = myapp-
  alien_pattern_version = ([\d\.]+)
  alien_pattern_suffix = \.tar\.gz
  alien_pattern = myapp-([\d\.]+)\.tar\.gz

=head1 ATTRIBUTES

=head2 author

This is used to name the L<CPAN|http://www.cpan.org/> author of the
distribution for the authority. See L<Dist::Zilla::Plugin::Authority/authority>.

=head2 authority

Override the authority used in metadata. Use this when uploading modules
originally owned by another CPAN author. For example, to upload modules
with ETHER as the authority:

  [@Author::GETTY]
  authority = ETHER

If not set, defaults to the C<author> value.

=head2 deprecated

Adds L<Dist::Zilla::Plugin::Deprecated> to the distribution.

=head2 release_branch

This variable is used to set the release_branch, only releases on this branch
will be allowed. See L<Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch/release_branch>.

=head2 weaver_config

This defines the L<PodWeaver> config that is used. See B<config_plugin> on
L<Dist::Zilla::Plugin::PodWeaver>.

=head2 no_github

If set to 1, this attribute will disable L<Dist::Zilla::Plugin::GithubMeta> and
will add L<Dist::Zilla::Plugin::Repository> instead. It also disables
L<Dist::Zilla::Plugin::GitHub::CreateRelease>.

When unset, the bundle auto-detects whether the repository has a remote
pointing at C<github.com> (by scanning F<.git/config>). If no GitHub remote is
found — e.g. the dist lives on GitLab, Codeberg, a private Gitea, or has no
remote at all — C<no_github> defaults to 1 so that the GitHub-specific plugins
are skipped entirely. Set C<no_github = 0> explicitly to force GitHub plugins
on even without a detected remote.

=head2 no_github_release

If set to 1, L<Dist::Zilla::Plugin::GitHub::CreateRelease> will not be used
even though GitHub integration is otherwise active. Like L</no_github>, this
defaults to 1 when no GitHub remote is detected in F<.git/config>.

When this option is B<not> set (the default), C<dzil release> will create a
GitHub Release for the new tag and attach the CPAN tarball. This requires a
F<~/.github-identity> file in your home directory with C<login> and C<token>
fields; the token needs write access to the repository's Contents. See
L<Config::Identity::GitHub> for authentication details (including GPG-encrypted
identity files).

=head2 no_cpan

If set to 1, this attribute will disable L<Dist::Zilla::Plugin::UploadToCPAN>.
By default a dzil release would release to L<CPAN|http://www.cpan.org/>.

=head2 no_changes

If set to 1, then L<Dist::Zilla::Plugin::NextRelease> (from @Git::VersionManager)
will not generate changes entries.

=head2 commit_files_after_release

Extra files to fold into the release commit, forwarded to
L<@Git::VersionManager|Dist::Zilla::PluginBundle::Git::VersionManager>'s
option of the same name (which wires them into the C<Git::Commit> plugin's
C<allow_dirty>). Useful for companion artefacts that are rewritten by a
C<run_before_release> hook and must ship in the same commit as the version
bump — e.g. a sibling Python/JS package version file.

Multi-value:

  [@Author::GETTY]
  run_before_release = xbin/release.pl python-prep %v
  commit_files_after_release = python/locale_simple.py
  commit_files_after_release = js/package.json

=head2 no_podweaver

If set to 1, then L<Dist::Zilla::Plugin::PodWeaver> is not used.

=head2 include_readme

By default, this bundle excludes F<README.md> from the gathered distribution
files. This keeps GitHub-specific Markdown READMEs out of release tarballs and
avoids awkward rendering on sites like MetaCPAN.

Set this attribute to 1 if you explicitly want to ship F<README.md> in the
distribution.

=head2 xs

If set to 1, then L<Dist::Zilla::Plugin::ModuleBuildTiny> is used for building.
This is suitable for pure-Perl XS modules that don't need external libraries.
This will also automatically set B<no_makemaker> to 1.

For XS modules that depend on Alien-provided libraries, use B<xs_alien> instead.

=head2 no_install

If set to 1, the resulting distribution can't be installed.

=head2 no_makemaker

If set to 1, the resulting distribution will not use L<Dist::Zilla::Plugin::MakeMaker>.
This is an internal function, and you should know what you do, if you activate
this flag.

=head2 no_installrelease

By default, this bundle will install your distribution after the release. If
you set this attribute to 1, then this will not happen. See
L<Dist::Zilla::Plugin::InstallRelease>.

If you use the L<Dist::Zilla::Plugin::Alien> options, then this one will not
use L<Dist::Zilla::Plugin::InstallRelease>, instead, it will use the trick
mentioned in L<Dist::Zilla::Plugin::Alien/InstallRelease>.

=head2 installrelease_command

If you don't like the usage of L<App::cpanminus> to install your distribution
after install, you can set another command here. See B<install_command> on
L<Dist::Zilla::Plugin::InstallRelease>.

=head2 irc

Specify an IRC channel for support. This will be added to the distribution
metadata and displayed in the SUPPORT section of the generated POD.

  [@Author::GETTY]
  irc = #perl

The channel name can be specified with or without the leading C<#>.

=head2 irc_server

Specify the IRC server. Defaults to C<irc.perl.org>.

  [@Author::GETTY]
  irc = #mychannel
  irc_server = irc.libera.chat

=head2 irc_user

Specify the IRC username to display in the SUPPORT section. Defaults to
C<Getty> when author is C<GETTY>.

If C<irc> is set but C<irc_user> is not, the IRC section will only mention
the channel without referencing a specific user.

  [@Author::GETTY]
  irc = #perl
  irc_user = Getty or ether

=head2 adoptme

If set to 1, this marks the distribution as available for adoption. This will
add C<x_adoptme> metadata to the distribution, which is recognized by
L<MetaCPAN|https://metacpan.org/> and displayed prominently to indicate that
the current maintainer is looking for someone to take over the module.

  [@Author::GETTY]
  adoptme = 1

=head2 alien_build

Set to 1 for distributions that use L<Alien::Build> to provide a C library.
This automatically sets B<no_makemaker> to 1 and adds
L<Dist::Zilla::Plugin::AlienBuild>, which generates a C<Makefile.PL> driven
by C<Alien::Build::MM>. Ship an C<alienfile> in the distribution root to
describe how to probe for or build the library.

  [@Author::GETTY]
  alien_build = 1

=head2 xs_alien

For XS modules that depend on an Alien-provided library, specify the Alien
module name. This automatically sets up L<Dist::Zilla::Plugin::MakeMaker::Awesome>
with the correct configuration:

  [@Author::GETTY]
  xs_alien = Alien::TinyCDB

The XS object name is derived from the Alien module name (e.g., C<Alien::TinyCDB>
becomes C<TinyCDB>). If your XS file has a different name, use B<xs_object>
to override:

  [@Author::GETTY]
  xs_alien = Alien::TinyCDB
  xs_object = MyXS

=head2 xs_object

Override the XS object name when using B<xs_alien>. By default, the object
name is derived from the Alien module name (the last component after C<::>).

=head2 version_finder

Restrict which files get a C<$VERSION> rewrite. Multi-value; accepts any
file finder name understood by the underlying version plugins (e.g.
C<:MainModule>, C<:InstallModules>, C<:ExecFiles>, or a custom
L<FileFinder|Dist::Zilla::Role::FileFinderUser/default_finders>).

By default this is unset and the version plugins use their own defaults
(C<:InstallModules> and C<:ExecFiles>). When you set it, the value is
forwarded to:

=over 4

=item *

L<Dist::Zilla::Plugin::PkgVersion> (used when B<task> or B<manual_version>
is set)

=item *

L<Dist::Zilla::Plugin::RewriteVersion::Transitional> and
L<Dist::Zilla::Plugin::BumpVersionAfterRelease> (used via
L<@Git::VersionManager|Dist::Zilla::PluginBundle::Git::VersionManager> on
the default release path)

=back

Typical use is restricting the rewrite to the main module so sibling
F<.pm> files in F<lib/> are not touched:

  [@Author::GETTY]
  version_finder = :MainModule

=head1 CONTINUOUS INTEGRATION

Every distribution using C<[@Author::GETTY]> can share the same CI mechanics
via a composite GitHub Action hosted in this bundle's repository:

  Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test

The action installs L<Dist::Zilla>, bootstraps all C<dist.ini> plugins via
C<dzil authordeps>, and then installs distribution prerequisites with
C<dzil listdeps --author>.  The C<--author> flag is essential: it includes
C<develop>-phase prerequisites such as L<Test::Pod>, which
L<Dist::Zilla::Plugin::PodSyntaxTests> (always active in this bundle) registers
as a C<develop requires>.  Without it, author tests will fail with a missing
module — do B<not> paper over this by adding C<Test::Pod> to the cpanfile's
C<on test> block.

=head2 Pure-Perl distributions

A minimal workflow for a pure-Perl dist (no system libraries required):

  # .github/workflows/ci.yml
  name: ci
  on:
    push:
      branches: ['*']
      tags-ignore: ['*']
    pull_request:
  jobs:
    test:
      runs-on: ubuntu-latest
      strategy:
        fail-fast: false
        matrix:
          perl-version: ['5.36', '5.38', '5.40']
      container:
        image: perl:${{ matrix.perl-version }}-bookworm
      steps:
        - uses: actions/checkout@v4
        - name: Fix safe.directory
          run: git config --global --add safe.directory "$GITHUB_WORKSPACE"
        - name: perl -V
          run: perl -V
        - uses: Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main

=head2 Alien / XS distributions (system libraries)

When the distribution wraps a C library, add system-library installation
before the shared action, and a second job that forces a vendored build:

  jobs:
    system-lib:
      runs-on: ubuntu-latest
      container:
        image: perl:5.40-bookworm
      steps:
        - uses: actions/checkout@v4
        - name: Fix safe.directory
          run: git config --global --add safe.directory "$GITHUB_WORKSPACE"
        - run: apt-get update && apt-get install -y libfoo-dev pkg-config
        - uses: Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main

    share-build:
      runs-on: ubuntu-latest
      container:
        image: perl:5.40-bookworm
      steps:
        - uses: actions/checkout@v4
        - name: Fix safe.directory
          run: git config --global --add safe.directory "$GITHUB_WORKSPACE"
        - run: apt-get update && apt-get install -y cmake build-essential
        - uses: Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main
          with:
            install-type: share

The C<install-type: share> input sets C<ALIEN_INSTALL_TYPE=share>, which forces
the dist to build and vendor the C library instead of using a system-provided one.

=head2 Forgejo / self-hosted Gitea

The composite action is forge-neutral (plain shell + cpanm + dzil).  On a
Forgejo instance, reference it with a fully-qualified URL so the action is
always fetched from GitHub regardless of the instance's
C<DEFAULT_ACTIONS_URL> setting:

  - uses: https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main

Alternatively, set C<DEFAULT_ACTIONS_URL = https://github.com> in the
Forgejo C<app.ini> and use the short form as on GitHub.

Forgejo reads workflow files from F<.github/workflows/> as well as
F<.forgejo/workflows/>, so the same YAML file works on both forges.

To verify that your Forgejo instance resolves the composite action correctly,
push a minimal probe workflow and watch the job log:

  # .forgejo/workflows/probe.yml
  name: probe
  on: [push]
  jobs:
    probe:
      runs-on: ubuntu-latest
      container:
        image: perl:5.40-bookworm
      steps:
        - uses: https://github.com/actions/checkout@v4
        - uses: https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main

If the action step fails to resolve (Forgejo does not yet support cross-repo
composite actions via subdirectory paths in all configurations), the fallback
is to vendor a copy of F<.github/actions/dzil-test/action.yml> directly into
each distribution repository and reference it locally:

  - uses: ./.github/actions/dzil-test

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Alien>

L<Dist::Zilla::Plugin::Authority>

L<Dist::Zilla::PluginBundle::Git>

L<Dist::Zilla::PluginBundle::Git::VersionManager>

L<Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch>

L<Dist::Zilla::Plugin::GitHub::CreateRelease>

L<Dist::Zilla::Plugin::GithubMeta>

L<Dist::Zilla::Plugin::InstallRelease>

L<Dist::Zilla::Plugin::MakeMaker::Awesome>

L<Dist::Zilla::Plugin::MakeMaker::SkipInstall>

L<Dist::Zilla::Plugin::MetaProvides::Package>

L<Dist::Zilla::Plugin::PodWeaver>

L<Dist::Zilla::Plugin::Repository>

L<Dist::Zilla::Plugin::Run>

L<Dist::Zilla::Plugin::TaskWeaver>

=head2 Docker Support

The bundle supports Docker image building via L<Dist::Zilla::Plugin::Docker::API>.
The simplest form is a single image — set C<docker_image> on the bundle and a
default Docker build/release pipeline is wired in for you:

  [@Author::GETTY]
  docker_image = registry/app
  docker_tags  = latest %v

That alone gives you a working Releaser (no separate C<[UploadToCPAN]> needed
for non-CPAN dists) — C<dzil build> builds the image, C<dzil release> tags
and pushes it.

For multi-target builds, add explicit C<[@Author::GETTY::Docker / name]>
subsections — each produces one independent C<Docker::API> plugin:

  [@Author::GETTY]
  docker_image    = registry/app
  docker_tags     = latest %v
  docker_default  = 0    ; suppress the auto-default; subsections handle it

  [@Author::GETTY::Docker / runtime-root]
  target = runtime-root

  [@Author::GETTY::Docker / runtime-user]
  target = runtime-user
  local  = 1
  tags   = user

Subsections inherit C<image>, C<tags>, and C<local> from the parent's
C<docker_image>, C<docker_tags>, and C<docker_local> settings, but each
subsection can override them individually. See
L<Dist::Zilla::PluginBundle::Author::GETTY::Docker> for the full attribute list.

=head2 docker_image

Docker image repository to publish to. When set, the bundle auto-adds a
single default L<Dist::Zilla::Plugin::Docker::API> plugin (via
L<[@Author::GETTY::Docker]|Dist::Zilla::PluginBundle::Author::GETTY::Docker>)
so C<dzil release> has a working Releaser without any extra config. Also
acts as the inherited default for any explicit C<[@Author::GETTY::Docker /
name]> subsections.

=head2 docker_tags

Whitespace-separated list of tags applied to the image. Default: C<latest
%V %v>. Inherited by subsections.

=head2 docker_local

If true, the image is built and tagged but not pushed. Inherited by
subsections.

=head2 docker_default

Defaults to true. Set to C<0> to suppress the auto-default plugin when
C<docker_image> is set — use this when you configure your Docker builds
exclusively through explicit C<[@Author::GETTY::Docker / name]> subsections
and don't want an extra plugin added behind your back.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
