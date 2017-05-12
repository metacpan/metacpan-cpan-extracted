use 5.006;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Author::KENTNL;

# ABSTRACT: BeLike::KENTNL when you build your distributions.

our $VERSION = '2.025021';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has );
use Moose::Util::TypeConstraints qw(enum);
use Dist::Zilla::Util::CurrentCmd qw( current_cmd );

with 'Dist::Zilla::Role::PluginBundle';
with 'Dist::Zilla::Role::PluginBundle::PluginRemover';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';
with 'Dist::Zilla::Role::BundleDeps';

use namespace::autoclean;


























sub mvp_multivalue_args { return qw( auto_prereqs_skip copy_files ) }

sub mvp_aliases {
  return {
    'bumpversions' => 'bump_versions',
    'srcreadme'    => 'src_readme',
    'copyfiles'    => 'copy_files',
  };
}











has 'plugins' => ( 'is' => 'ro' =>, 'isa' => 'ArrayRef', 'init_arg' => undef, 'lazy' => 1, 'default' => sub { [] } );













has 'normal_form' => ( 'is' => ro =>, 'isa' => 'Str', lazy => 1, default => sub { 'numify' } );











has 'mantissa' => (
  'is'      => ro =>,
  'isa'     => 'Int',
  'lazy'    => 1,
  'default' => sub {
    return 6;
  },
);



















has 'git_versions' => ( is => 'ro', isa => 'Any', lazy => 1, default => sub { undef } );









has 'authority' => ( is => 'ro', isa => 'Str', lazy => 1, default => sub { 'cpan:KENTNL' }, );









has 'auto_prereqs_skip' => (
  is        => 'ro',
  isa       => 'ArrayRef',
  predicate => 'has_auto_prereqs_skip',
  lazy      => 1,
  default   => sub { [] },
);









has 'twitter_extra_hash_tags' => (
  is        => 'ro',
  'isa'     => 'Str',
  lazy      => 1,
  predicate => 'has_twitter_extra_hash_tags',
  default   => sub { q[] },
);









has 'twitter_hash_tags' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    my ($self) = @_;
    return '#perl #cpan' unless $self->has_twitter_extra_hash_tags;

    return '#perl #cpan ' . $self->twitter_extra_hash_tags;
  },
);









has 'tweet_url' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    ## no critic (RequireInterpolationOfMetachars)
    return q[https://metacpan.org/release/{{$AUTHOR_UC}}/{{$DIST}}-{{$VERSION}}{{$TRIAL}}#whatsnew];
  },
);





















has 'toolkit_hardness' => (
  is => ro =>,
  isa => enum( [ 'hard', 'soft' ] ),
  lazy    => 1,
  default => sub { 'hard' },
);



















has 'toolkit' => (
  is => ro =>,
  isa => enum( [ 'mb', 'mbtiny', 'eumm' ] ),
  lazy    => 1,
  default => sub { 'mb' },
);










has 'bump_versions' => (
  is      => ro  =>,
  isa     => 'Bool',
  lazy    => 1,
  default => sub { undef },
);
















has copy_files => (
  is   => ro =>,
  isa  => 'ArrayRef[ Str ]',
  lazy => 1,
  default => sub { [ 'LICENSE', 'Makefile.PL' ] },
);









has src_readme => (
  is => ro =>,
  isa => enum( [ 'pod', 'mkdn', 'none' ] ),
  lazy    => 1,
  default => sub { return 'mkdn'; },
);

__PACKAGE__->meta->make_immutable;
no Moose;
no Moose::Util::TypeConstraints;







sub add_plugin {
  my ( $self, $suffix, $conf ) = @_;
  if ( not defined $conf ) {
    $conf = {};
  }
  if ( not ref $conf or not 'HASH' eq ref $conf ) {
    require Carp;
    Carp::croak('Conf must be a hash');
  }
  ## no critic (RequireInterpolationOfMetachars)
  push @{ $self->plugins }, [ q{@Author::KENTNL/} . $suffix, 'Dist::Zilla::Plugin::' . $suffix, $conf ];
  return;
}







sub add_named_plugin {
  my ( $self, $name, $suffix, $conf ) = @_;
  if ( not defined $conf ) {
    $conf = {};
  }
  if ( not ref $conf or not 'HASH' eq ref $conf ) {
    require Carp;
    Carp::croak('Conf must be a hash');
  }
  ## no critic (RequireInterpolationOfMetachars)
  push @{ $self->plugins }, [ q{@Author::KENTNL/} . $name, 'Dist::Zilla::Plugin::' . $suffix, $conf ];
  return;
}







sub _is_bake { return ( current_cmd() and 'bakeini' eq current_cmd() ) }

sub _configure_bump_versions_version {
  my ( $self, ) = @_;
  return if $self->bump_versions;
  $self->add_plugin(
    'Git::NextVersion::Sanitized' => {
      version_regexp => '^(.*)-source$',
      first_version  => '0.001000',
      normal_form    => $self->normal_form,
      mantissa       => $self->mantissa,
    },
  );
  return;
}

sub _configure_basic_metadata {
  my ( $self, ) = @_;

  $self->add_plugin( 'MetaConfig'            => {}, );
  $self->add_plugin( 'GithubMeta'            => { issues => 1 }, );
  $self->add_plugin( 'MetaProvides::Package' => { ':version' => '1.14000001' }, );

  my $builtwith_options = {
    ':version'        => '1.004000',
    show_config       => 1,
    use_external_file => 'only',
  };

  if ( 'linux' eq $^O ) {
    $builtwith_options->{show_uname} = 1;
    $builtwith_options->{uname_args} = q{-s -o -r -m -i};
  }

  $self->add_plugin( 'MetaData::BuiltWith' => $builtwith_options );
  $self->add_plugin(
    'Git::Contributors' => {
      ':version'       => '0.006',
      include_authors  => 0,
      include_releaser => 0,
      order_by         => 'name',
    },
  );

  return;
}

sub _none_match {
  my ( $item, @list ) = @_;
  for my $list_item (@list) {
    return if $item eq $list_item;
  }
  return 1;
}

sub _configure_basic_files {
  my ($self)         = @_;
  my (@ignore_files) = qw( README README.mkdn README.pod CONTRIBUTING.pod );
  my (@copy_files)   = ();

  if ( _none_match 'none', @{ $self->copy_files } ) {
    push @copy_files, @{ $self->copy_files };
  }
  push @ignore_files, @copy_files;

  $self->add_plugin(
    'Git::GatherDir' => {
      include_dotfiles => 1,
      exclude_filename => [@ignore_files],
    },
  );
  $self->add_plugin( 'License' => {} );

  $self->add_plugin( 'MetaJSON'                 => {} );
  $self->add_plugin( 'MetaYAML::Minimal'        => {} );
  $self->add_plugin( 'Manifest'                 => {} );
  $self->add_plugin( 'Author::KENTNL::TravisCI' => { ':version' => '0.001002' } );
  $self->add_plugin(
    'Author::KENTNL::CONTRIBUTING' => {
      ':version'       => '0.001003',
      document_version => '0.1',
      '-location'      => 'root',       # Assuming my patches get merged in future
      '-phase'         => 'build',
    },
  );

  if (@copy_files) {
    $self->add_named_plugin( 'CopyXBuild' => 'CopyFilesFromBuild', { copy => [@copy_files] } );
  }

  return;
}

sub _configure_basic_tests {
  my ($self) = @_;
  $self->add_plugin( 'MetaTests'            => {} );
  $self->add_plugin( 'PodCoverageTests'     => {} );
  $self->add_plugin( 'PodSyntaxTests'       => {} );
  $self->add_plugin( 'Test::ReportPrereqs'  => {} );
  $self->add_plugin( 'Test::Kwalitee'       => {} );
  $self->add_plugin( 'Test::EOL'            => { trailing_whitespace => 1, } );
  $self->add_plugin( 'Test::MinimumVersion' => {} );
  $self->add_plugin(
    'Test::Compile::PerFile' => {
      ':version'      => '0.003902',
      'test_template' => '02-raw-require.t.tpl',
    },
  );
  $self->add_plugin( 'Test::Perl::Critic' => {} );
  return;
}

sub _configure_pkgversion_munger {
  my ($self) = @_;
  if ( not $self->bump_versions ) {
    $self->add_plugin( 'PkgVersion' => {} );
    return;
  }
  $self->add_plugin(
    'RewriteVersion::Sanitized' => {
      normal_form => $self->normal_form,
      mantissa    => $self->mantissa,
    },
  );
  return;
}

sub _configure_bundle_develop_suggests {
  my ($self) = @_;
  my $deps = {
    -phase => 'develop',
    -type  => 'suggests',
  };
  if ( _is_bake() ) {
    $deps->{'Dist::Zilla::PluginBundle::Author::KENTNL'} = $VERSION;
    $deps->{'Dist::Zilla::App::Command::bakeini'}        = '0.001000';
  }
  else {
    $deps->{'Dist::Zilla::PluginBundle::Author::KENTNL::Lite'} = '1.3.0';
  }
  $self->add_named_plugin( 'BundleDevelSuggests' => 'Prereqs' => $deps );
  return;
}

sub _configure_bundle_develop_requires {
  my ($self) = @_;
  return if _is_bake();
  $self->add_named_plugin(
    'BundleDevelRequires' => 'Prereqs' => {
      -phase                                      => 'develop',
      -type                                       => 'requires',
      'Dist::Zilla::PluginBundle::Author::KENTNL' => $VERSION,
    },
  );
  return;
}

sub _configure_toolkit {
  my ($self) = @_;
  my $tk = $self->toolkit;
tc_select: {
    if ( 'mb' eq $tk ) {
      $self->add_plugin( 'ModuleBuild' => { default_jobs => 10 } );
      last tc_select;
    }
    if ( 'eumm' eq $tk ) {
      $self->add_plugin( 'MakeMaker' => { default_jobs => 10 } );
      last tc_select;
    }
    if ( 'mbtiny' eq $tk ) {
      $self->add_plugin( 'ModuleBuildTiny' => { default_jobs => 10 } );
      last tc_select;
    }
  }
  $self->add_plugin( 'Author::KENTNL::RecommendFixes' => { ':version' => '0.004002' } );
  return;
}

sub _configure_toolkit_prereqs {
  my ($self) = @_;

  my $extra_match_installed = { 'Test::More' => '0.99', };

  $extra_match_installed->{'Module::Build'}       = '0.4004' if 'mb' eq $self->toolkit;
  $extra_match_installed->{'Module::Build::Tiny'} = '0.032'  if 'mbtiny' eq $self->toolkit;
  $extra_match_installed->{'ExtUtils::MakeMaker'} = '7.00'   if 'eumm' eq $self->toolkit;

  if ( 'hard' eq $self->toolkit_hardness ) {
    $self->add_plugin(
      'Prereqs::MatchInstalled' => {
        modules => [ sort keys %{$extra_match_installed} ],
      },
    );
  }

  $self->add_plugin(
    'Prereqs::Upgrade' => {
      %{$extra_match_installed},
      'Moose'                                     => '2.000',       # Module::Runtime crap
      'Moo'                                       => '1.000008',    # lazy_build => sub
      'Path::Tiny'                                => '0.058',       # ->sibling
      'File::ShareDir::Install'                   => '0.10',        # dotfiles
      'Dist::Zilla'                               => '5',           # encoding
      'Test::File::ShareDir'                      => '1.000000',    # 5.8 version compat
      'Dist::Zila::Plugin::MetaProvides::Package' => '2.000000',    # sane version
    },
  );

  my $applymap = [ 'develop.requires = develop.requires', ];

  $applymap = [ 'develop.suggests = develop.suggests', ] if _is_bake();

  my @bundles = ('Dist::Zilla::PluginBundle::Author::KENTNL');

  push @bundles, 'Dist::Zilla::App::Command::bakeini' if _is_bake();

  $self->add_named_plugin(
    'always_latest_develop_bundle' => 'Prereqs::Recommend::MatchInstalled' => {
      applyto_map   => $applymap,
      applyto_phase => [ 'develop', ],
      modules       => [@bundles],
    },
  );
  $self->add_plugin( 'RemovePrereqs::Provided' => {} );
  return;
}

sub _configure_readmes {
  my ($self) = @_;

  $self->add_named_plugin( 'ShippedReadme' => 'Readme::Brief' => {}, );

  my $type = $self->src_readme;

  return if 'none' eq $type;

  my $map = {};
  $map->{mkdn} = { type => 'markdown', filename => 'README.mkdn' };
  $map->{pod}  = { type => 'pod',      filename => 'README.pod' };

  if ( not exists $map->{$type} ) {
    require Carp;
    return Carp::confess("No known readme type $type");
  }

  $self->add_plugin( 'ReadmeAnyFromPod' => { location => 'root', %{ $map->{$type} } }, );

  return;
}

sub configure {
  my ($self) = @_;

  # Version
  $self->_configure_bump_versions_version;

  # MetaData
  $self->_configure_basic_metadata;

  # Gather Files
  $self->_configure_basic_files;
  $self->_configure_basic_tests;

  # Prune files

  $self->add_plugin( 'ManifestSkip' => {} );

  # Mungers
  $self->_configure_pkgversion_munger;
  $self->add_plugin(
    'PodWeaver' => {
      replacer => 'replace_with_blank',
    },
  );

  # Prereqs

  {
    my $autoprereqs_hash = {};
    $autoprereqs_hash->{skips} = $self->auto_prereqs_skip if $self->has_auto_prereqs_skip;
    $self->add_plugin( 'AutoPrereqs' => $autoprereqs_hash );
  }

  $self->_configure_bundle_develop_suggests();
  $self->_configure_bundle_develop_requires();

  $self->add_plugin( 'Prereqs::AuthorDeps' => {} );

  $self->add_plugin( 'MinimumPerl' => {} );
  $self->add_plugin(
    'Authority' => {
      ':version'     => '1.006',
      authority      => $self->authority,
      do_metadata    => 1,
      locate_comment => 1,
    },
  );

  $self->_configure_toolkit;

  $self->_configure_readmes;

  $self->add_plugin( 'Test::CPAN::Changes' => {} );
  $self->add_plugin( 'RunExtraTests'       => { default_jobs => 10 } );
  $self->add_plugin( 'TestRelease'         => {} );
  $self->add_plugin( 'ConfirmRelease'      => {} );

  $self->add_plugin( 'Git::Check' => { filename => 'Changes' } );
  $self->add_named_plugin( 'commit_dirty_files' => 'Git::Commit' => {} );
  $self->add_named_plugin( 'tag_master', => 'Git::Tag' => { tag_format => '%v-source' } );
  $self->add_plugin(
    'Git::NextRelease' => {
      ':version'     => '0.004000',
      time_zone      => 'UTC',
      format         => q[%v %{yyyy-MM-dd'T'HH:mm:ss}dZ %h],
      default_branch => 'master',
    },
  );

  if ( $self->bump_versions ) {
    $self->add_plugin( 'BumpVersionAfterRelease' => {} );
  }
  $self->add_named_plugin(
    'commit_release_changes' => 'Git::Commit' => {
      allow_dirty_match => '^lib/',
    },
  );

  $self->add_plugin( 'Git::CommitBuild' => { branch => 'builds', release_branch => 'releases' } );
  $self->add_named_plugin( 'tag_release', 'Git::Tag' => { branch => 'releases', tag_format => '%v' } );
  $self->add_plugin( 'UploadToCPAN' => {} );
  $self->add_plugin(
    'Twitter' => {
      hash_tags     => $self->twitter_hash_tags,
      tweet_url     => $self->tweet_url,
      url_shortener => 'none',
    },
  );

  $self->_configure_toolkit_prereqs;

  return;
}

sub BUILDARGS {
  my ( $self, $config, @args ) = @_;

  if ( @args or not 'HASH' eq ( ref $config || q[] ) ) {
    $config = { $config, @args };
  }
  my (%init_args);
  for my $attr ( $self->meta->get_all_attributes ) {
    next unless my $arg = $attr->init_arg;
    $init_args{$arg} = 1;
  }

  # A weakened warn-only filter-supporting StrictConstructor
  for my $key ( keys %{$config} ) {
    next if exists $init_args{$key};
    next if $key =~ /\A-remove/msx;
    next if $key =~ /\A[^.]+[.][^.]/msx;
    require Carp;
    Carp::carp("Unknown key $key");
  }
  return $config;
}

sub bundle_config {
  my ( $self, $section ) = @_;
  my $class = ( ref $self ) || $self;

  my $wanted_version;
  if ( exists $section->{payload}->{':version'} ) {
    $wanted_version = delete $section->{payload}->{':version'};
  }
  my $instance = $class->new( $section->{payload} );

  $instance->configure();

  return @{ $instance->plugins };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::KENTNL - BeLike::KENTNL when you build your distributions.

=head1 VERSION

version 2.025021

=head1 SYNOPSIS

    [@Author::KENTNL]
    normal_form  = numify ; Mandatory for this bundle indicating normal form.
                          ; see DZP::Git::NextVersion::Sanitized

    mantissa     = 6      ; Mandatory for this bundle if normal_form is numify.
                          ; see DZP::Git::NextVersion::Sanitized

    authority    = cpan:KENTNL ; Optional, defaults to cpan:KENTNL

    auto_prereqs_skip   = Some::Module  ; Hide these from autoprereqs
    auto_prereqs_skip   = Other::Module

    toolkit     = mb   ; Which toolkit to use. Either eumm or mb
                         ; mb is default.

    toolkit_hardness = hard ; Whether to upgrade *require* deps to the latest
                            ; or wether to make them merely recomendations.
                            ; Either 'soft' ( recommend ) or 'hard' ( require )
                            ; default is 'hard'

    twitter_extra_hash_tags = #foo #bar ; non-default hashtags to append to the tweet

=head1 DESCRIPTION

This is the plug-in bundle that KENTNL uses. It exists mostly because he is very lazy
and wants others to be using what he's using if they want to be doing work on his modules.

=head1 NAMING SCHEME

As I blogged about on L<< C<blog.fox.geek.nz> : Making a Minting Profile as a CPANized Dist |http://bit.ly/hAwl4S >>,
this bundle advocates a new naming system for people who are absolutely convinced they want their C<Author-Centric> distribution
uploaded to CPAN.

As we have seen with Dist::Zilla there have been a slew of PluginBundles with CPANID's in their name, to the point that there is
a copious amount of name-space pollution in the PluginBundle name-space, and more Author bundles than task-bundles, which was
really what the name-space was designed for, and I'm petitioning you to help reduce this annoyance in future modules.

From a CPAN testers perspective, the annoyance of lots of CPANID-dists is similar to the annoyance of the whole DPCHRIST::
subspace, and that if this pattern continues, it will mean for the testers who do not wish to test everyones personal modules,
that they will have to work hard to avoid this. If DPCHRIST:: had used something like Author::DPCHRIST:: instead, I doubt so many
people would be horrified by it, because you can just have a policy/rule that excludes ^Author::, and everyone else who goes that
way can be quietly ignored.

Then we could probably rationally add that same restriction to the irc announce bots, the "recent modules" list and so-forth, and
possibly even apply special indexing restrictions or something so people wouldn't even have to know those modules exist on cpan!

So, for the sake of cleanliness, semantics, and general global sanity, I ask you to join me with my Author:: naming policy to
voluntarily segregate modules that are most likely of only personal use from those that have more general application.

    Dist::Zilla::Plugin::Foo                    # [Foo]                 dist-zilla plugins for general use
    Dist::Zilla::Plugin::Author::KENTNL::Foo    # [Author::KENTNL::Foo] foo that only KENTNL will probably have use for
    Dist::Zilla::PluginBundle::Classic          # [@Classic]            A bundle that can have practical use by many
    Dist::Zilla::PluginBundle::Author::KENTNL   # [@Author::KENTNL]     KENTNL's primary plugin bundle
    Dist::Zilla::MintingProfile::Default        # A minting profile that is used by all
    Dist::Zilla::MintingProfile::Author::KENTNL # A minting profile that only KENTNL will find of use.

=head2 Current Proponents

I wish to give proper respect to the people out there already implementing this scheme:

=over 4

=item L<< C<@Author::DOHERTY> |Dist::Zilla::PluginBundle::Author::DOHERTY >> - Mike Doherty's, Author Bundle.

=item L<< C<@Author::OLIVER> |Dist::Zilla::PluginBundle::Author::OLIVER >> - Oliver Gorwits', Author Bundle.

=item L<< C<Dist::Zilla::PluginBundle::Author::> namespace |http://bit.ly/dIovQI >> - Oliver Gorwit's blog on the subject.

=item L<< C<@Author::LESPEA> |Dist::Zilla::PluginBundle::Author::LESPEA >> - Adam Lesperance's, Author Bundle.

=item L<< C<@Author::ALEXBIO> |Dist::Zilla::PluginBundle::Author::ALEXBIO >> - Alessandro Ghedini's, Author Bundle.

=item L<< C<@Author::RWSTAUNER> |Dist::Zilla::PluginBundle::Author::RWSTAUNER >> - Randy Stauner's, Author Bundle.

=item L<< C<@Author::WOLVERIAN> |Dist::Zilla::PluginBundle::Author::WOLVERIAN >> - Ilmari Vacklin's, Author Bundle.

=item L<< C<@Author::YANICK> |Dist::Zilla::PluginBundle::Author::YANICK >> - Yanick Champoux's, Author Bundle.

=item L<< C<@Author::RUSSOZ> |Dist::Zilla::PluginBundle::Author::RUSSOZ >> - Alexei Znamensky's, Author Bundle.

=back

=head1 METHODS

=head2 C<bundle_config>

See L<< the C<PluginBundle> role|Dist::Zilla::Role::PluginBundle >> for what this is for, it is a method to satisfy that role.

=head2 C<add_plugin>

    $bundle_object->add_plugin("Basename" => { config_hash } );

=head2 C<add_named_plugin>

    $bundle_object->add_named_plugin("alias" => "Basename" => { config_hash } );

=head2 C<configure>

Called by in C<bundle_config> after C<new>

=head1 ATTRIBUTES

=head2 C<plugins>

B<INTERNAL>.

  ArrayRef, ro, default = [], no init arg.

Populated during C<< $self->configure >> and returned from C<< ->bundle_config >>

=head2 C<normal_form>

  Str, ro, lazy

A C<normal_form> to pass to L<< C<[Git::NextVersion::Sanitized]>|Dist::Zilla::Plugin::Git::NextVersion::Sanitized >>.

Defaults to C<numify>

See L<< C<[::Role::Version::Sanitize]>|Dist::Zilla::Role::Version::Sanitize >>

=head2 C<mantissa>

  Int, ro, defaults to 6.

Defines the length of the mantissa when normal form is C<numify>.

See L<< C<[Git::NextVersion::Sanitized]>|Dist::Zilla::Plugin::Git::NextVersion::Sanitized >> and L<< C<[::Role::Version::Sanitize]>|Dist::Zilla::Role::Version::Sanitize >>

=head2 C<git_versions>

  Any, unused.

=over 4

=item * B<UNUSED>

=back

Since C<2.020>, this field is no longer required, and is unused, simply supported for legacy reasons.

Things may not work if code has not been portaged to be C<Git::NextVersion> safe, but that's better than going "bang".

But code will be assumed to be using C<Git::NextVersion>.

=head2 C<authority>

  Str, ro, default = cpan:KENTNL

An authority string to use for C<< [Authority] >>.

=head2 C<auto_prereqs_skip>

  ArrayRef, ro, multivalue, default = []

A list of prerequisites to pass to C<< [AutoPrereqs].skips >>

=head2 C<twitter_extra_hash_tags>

  Str, ro, default = ""

Additional hash tags to append to twitter

=head2 C<twitter_hash_tags>

  Str, ro, default = '#perl #cpan' . extras()

Populates C<extras> from C<twitter_extra_hash_tags>

=head2 C<tweet_url>

  Str, ro, default =  q[https://metacpan.org/release/{{$AUTHOR_UC}}/{{$DIST}}-{{$VERSION}}{{$TRIAL}}#whatsnew]

The C<URI> to tweet to C<@kentnlrelease>

=head2 C<toolkit_hardness>

  enum( hard, soft ), ro, default = hard

=over 4

=item * C<hard>

Copy the versions of important toolkit components the author was using as C<required> dependencies,
forcing consumers to update aggressively on those parts.

=item * C<soft>

Copy the versions of important toolkit components the author was using as C<recommended> dependencies,
so that only consumers who are installing with C<--with-recommended> get given the forced upgrade path.

=back

=head2 C<toolkit>

  enum( mb, mbtiny, eumm ), ro, default = mb

Determines which tooling to generate the distribution with

=over 4

=item * C<mb> : L<< C<Module::Build>|Module::Build >>

=item * C<mbtiny> : L<< C<Module::Build::Tiny>|Module::Build::Tiny >>

=item * C<eumm> : L<< C<ExtUtils::MakeMaker>|ExtUtils::MakeMaker >>

=back

=head2 C<bump_versions>

  bump_versions = 1

If true, use C<[BumpVersionAfterRelease]>  and C<[RewriteVersions::Sanitized]> instead of C<[PkgVersion]> and
C<[Git::NextVersion::Sanitized]>

=head2 C<copy_files>

An array of files generated by C<Dist::Zilla> build to copy from the built dist back to the source dist

If not specified, the default contents are as follows:

  copy_files = LICENSE
  copy_files = Makefile.PL

These defaults can be wiped with:

  copy_files = none

=head2 C<src_readme>

  src_readme = pod  ; # generate README.pod on the source side
  src_readme = mkdn ; # generate README.mkdn on the source side
  src_readme = none ; # don't generate README on the source side

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::PluginBundle::Author::KENTNL",
    "interface":"class",
    "inherits":"Moose::Object",
    "does":"Dist::Zilla::Role::PluginBundle"
}


=end MetaPOD::JSON

=for Pod::Coverage   mvp_multivalue_args
  mvp_aliases
  bundle_config_inner

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
