package Dist::Zilla::PluginBundle::Author::GETTY;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: BeLike::GETTY when you build your dists
our $VERSION = '0.202';
use Moose;
use Moose::Autobox;
use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';


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
  default => sub { $_[0]->payload->{release_branch} || 'master' },
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
  default => sub { $_[0]->payload->{no_github} },
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
  default => sub { $_[0]->payload->{no_makemaker} || $_[0]->is_alien || $_[0]->xs },
);

has no_podweaver => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{no_podweaver} },
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

my @alien_attributes = map { 'alien_'.$_ } @alien_options;

for my $attr (@alien_attributes) {
  has $attr => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { defined $_[0]->payload->{$attr} ? $_[0]->payload->{$attr} : "" },
  );
}

has alien_bin_requires => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { defined $_[0]->payload->{alien_bin_requires} ? $_[0]->payload->{alien_bin_requires} : [] },
);

sub mvp_multivalue_args { @run_attributes, @gather_array_attributes, 'alien_bin_requires' }

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
    scalar @{$self->gather_exclude_filename} > 0 ? ( exclude_filename => $self->gather_exclude_filename ) : (),
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

  if ($self->xs) {
    $self->add_plugins(qw(
      ModuleBuildTiny
    ));
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
    $self->add_plugins('PkgVersion');
  }

  $self->add_plugins(qw(
    MetaConfig
    MetaJSON
    PodSyntaxTests
  ));

  $self->add_plugins($self->no_github ? 'Repository' : 'GithubMeta');

  if ($self->is_alien) {
    my %alien_values;
    for (@alien_options) {
      my $func = 'alien_'.$_;
      $alien_values{$_} = $self->$func if defined $self->$func && $self->$func ne '';
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
        authority => 'cpan:'.$self->author,
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
      'Git::Push.push_to' => 'origin',
      $self->no_changes ? ( 'NextRelease.format' => '' ) : (),
    });
  } else {
    $self->add_bundle('@Git' => {
      tag_format => '%v',
      push_to    => [ qw(origin) ],
    });
  }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::GETTY - BeLike::GETTY when you build your dists

=head1 VERSION

version 0.202

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
  deprecated = 0
  release_branch = master
  weaver_config = @Author::GETTY
  no_cpan = 0
  no_install = 0
  no_makemaker = 0
  no_installrelease = 0
  no_changes = 0
  no_podweaver = 0
  xs = 0
  installrelease_command = cpanm .

In default configuration it is equivalent to:

  [@Filter]
  -bundle = @Basic
  -remove = GatherDir
  -remove = PruneCruft

  [PkgVersion]
  [MetaConfig]
  [MetaJSON]
  [PodSyntaxTests]
  [GithubMeta]

  [InstallRelease]
  install_command = cpanm .

  [Authority]
  authority = cpan:GETTY
  do_metadata = 1

  [PodWeaver]
  config_plugin = @Author::GETTY

  [Repository]

  [Git::CheckFor::CorrectBranch]
  release_branch = master

  [@Git::VersionManager]
  ; handles versioning, changelog (NextRelease), commits, tags, and push

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
distribution. See L<Dist::Zilla::Plugin::Authority/authority>.

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
will add L<Dist::Zilla::Plugin::Repository> instead.

=head2 no_cpan

If set to 1, this attribute will disable L<Dist::Zilla::Plugin::UploadToCPAN>.
By default a dzil release would release to L<CPAN|http://www.cpan.org/>.

=head2 no_changes

If set to 1, then L<Dist::Zilla::Plugin::NextRelease> (from @Git::VersionManager)
will not generate changes entries.

=head2 no_podweaver

If set to 1, then L<Dist::Zilla::Plugin::PodWeaver> is not used.

=head2 xs

If set to 1, then L<Dist::Zilla::Plugin::ModuleBuildTiny>. This will also
automatically set B<no_makemaker> to 1.

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

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Alien>

L<Dist::Zilla::Plugin::Authority>

L<Dist::Zilla::PluginBundle::Git>

L<Dist::Zilla::PluginBundle::Git::VersionManager>

L<Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch>

L<Dist::Zilla::Plugin::GithubMeta>

L<Dist::Zilla::Plugin::InstallRelease>

L<Dist::Zilla::Plugin::MakeMaker::SkipInstall>

L<Dist::Zilla::Plugin::PodWeaver>

L<Dist::Zilla::Plugin::Repository>

L<Dist::Zilla::Plugin::Run>

L<Dist::Zilla::Plugin::TaskWeaver>

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty>

  git clone https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
