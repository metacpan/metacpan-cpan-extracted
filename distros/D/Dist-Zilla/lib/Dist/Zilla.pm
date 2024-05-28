package Dist::Zilla 6.032;
# ABSTRACT: distribution builder; installer not included!

use Moose 0.92; # role composition fixes
with 'Dist::Zilla::Role::ConfigDumper';

use Dist::Zilla::Pragmas;

# This comment has fün̈n̈ÿ characters.

use MooseX::Types::Moose qw(ArrayRef Bool HashRef Object Str);
use MooseX::Types::Perl qw(DistName LaxVersionStr);
use Moose::Util::TypeConstraints;

use Dist::Zilla::Types qw(Path License ReleaseStatus);

use Log::Dispatchouli 1.100712; # proxy_loggers, quiet_fatal
use Dist::Zilla::Path;
use List::Util 1.33 qw(first none);
use Software::License 0.104001; # ->program
use String::RewritePrefix;
use Try::Tiny;

use Dist::Zilla::Prereqs;
use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Role::Plugin;
use Dist::Zilla::Util;
use Module::Runtime 'require_module';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Dist::Zilla builds distributions of code to be uploaded to the CPAN.  In this
#pod respect, it is like L<ExtUtils::MakeMaker>, L<Module::Build>, or
#pod L<Module::Install>.  Unlike those tools, however, it is not also a system for
#pod installing code that has been downloaded from the CPAN.  Since it's only run by
#pod authors, and is meant to be run on a repository checkout rather than on
#pod published, released code, it can do much more than those tools, and is free to
#pod make much more ludicrous demands in terms of prerequisites.
#pod
#pod If you have access to the web, you can learn more and find an interactive
#pod tutorial at B<L<dzil.org|https://dzil.org/>>.  If not, try
#pod L<Dist::Zilla::Tutorial>.
#pod
#pod =cut

has chrome => (
  is  => 'rw',
  isa => role_type('Dist::Zilla::Role::Chrome'),
  required => 1,
);

#pod =attr name
#pod
#pod The name attribute (which is required) gives the name of the distribution to be
#pod built.  This is usually the name of the distribution's main module, with the
#pod double colons (C<::>) replaced with dashes.  For example: C<Dist-Zilla>.
#pod
#pod =cut

has name => (
  is   => 'ro',
  isa  => DistName,
  lazy => 1,
  builder => '_build_name',
);

#pod =attr version
#pod
#pod This is the version of the distribution to be created.
#pod
#pod =cut

has _version_override => (
  isa => LaxVersionStr,
  is  => 'ro' ,
  init_arg => 'version',
);

# XXX: *clearly* this needs to be really much smarter -- rjbs, 2008-06-01
has version => (
  is   => 'rw',
  isa  => LaxVersionStr,
  lazy => 1,
  init_arg  => undef,
  builder   => '_build_version',
);

sub _build_name {
  my ($self) = @_;

  my $name;
  for my $plugin (@{ $self->plugins_with(-NameProvider) }) {
    next unless defined(my $this_name = $plugin->provide_name);

    $self->log_fatal('attempted to set name twice') if defined $name;

    $name = $this_name;
  }

  $self->log_fatal('no name was ever set') unless defined $name;

  $name;
}

sub _build_version {
  my ($self) = @_;

  my $version = $self->_version_override;

  for my $plugin (@{ $self->plugins_with(-VersionProvider) }) {
    next unless defined(my $this_version = $plugin->provide_version);

    $self->log_fatal('attempted to set version twice') if defined $version;

    $version = $this_version;
  }

  $self->log_fatal('no version was ever set') unless defined $version;

  $version;
}

#pod =attr release_status
#pod
#pod This attribute sets the release status to one of the
#pod L<CPAN::META::Spec|https://metacpan.org/pod/CPAN::Meta::Spec#release_status>
#pod values: 'stable', 'testing' or 'unstable'.
#pod
#pod If the C<$ENV{RELEASE_STATUS}> environment variable exists, its value will
#pod be used as the release status.
#pod
#pod For backwards compatibility, if C<$ENV{RELEASE_STATUS}> does not exist and
#pod the C<$ENV{TRIAL}> variable is true, the release status will be 'testing'.
#pod
#pod Otherwise, the release status will be set from a
#pod L<ReleaseStatusProvider|Dist::Zilla::Role::ReleaseStatusProvider>, if one
#pod has been configured.
#pod
#pod For backwards compatibility, setting C<is_trial> true in F<dist.ini> is
#pod equivalent to using a C<ReleaseStatusProvider>.  If C<is_trial> is false,
#pod it has no effect.
#pod
#pod Only B<one> C<ReleaseStatusProvider> may be used.
#pod
#pod If no providers are used, the release status defaults to 'stable' unless there
#pod is an "_" character in the version, in which case, it defaults to 'testing'.
#pod
#pod =cut

# release status must be lazy, after files are gathered
has release_status => (
  is => 'ro',
  isa => ReleaseStatus,
  lazy => 1,
  builder => '_build_release_status',
);

sub _build_release_status {
  my ($self) = @_;

  # environment variables override completely
  return $self->_release_status_from_env if $self->_release_status_from_env;

  # other ways of setting status must not conflict
  my $status;

  # dist.ini is equivalent to a release provider if is_trial is true.
  # If false, though, we want other providers to run or fall back to
  # the version
  $status = 'testing' if $self->_override_is_trial;

  for my $plugin (@{ $self->plugins_with(-ReleaseStatusProvider) }) {
    next unless defined(my $this_status = $plugin->provide_release_status);

    $self->log_fatal('attempted to set release status twice')
      if defined $status;

    $status = $this_status;
  }

  return $status || ( $self->version =~ /_/ ? 'testing' : 'stable' );
}

# captures environment variables early during Zilla object construction
has _release_status_from_env => (
  is => 'ro',
  isa => Str,
  builder => '_build_release_status_from_env',
);

sub _build_release_status_from_env {
  my ($self) = @_;
  return $ENV{RELEASE_STATUS} if $ENV{RELEASE_STATUS};
  return $ENV{TRIAL} ? 'testing' : '';
}

#pod =attr abstract
#pod
#pod This is a one-line summary of the distribution.  If none is given, one will be
#pod looked for in the L</main_module> of the dist.
#pod
#pod =cut

has abstract => (
  is   => 'rw',
  isa  => 'Str',
  lazy => 1,
  default  => sub {
    my ($self) = @_;

    unless ($self->main_module) {
      die "no abstract given and no main_module found; make sure your main module is in ./lib\n";
    }

    my $file = $self->main_module;
    $self->log_debug("extracting distribution abstract from " . $file->name);
    my $abstract = Dist::Zilla::Util->abstract_from_file($file);

    if (!defined($abstract)) {
        my $filename = $file->name;
        die "Unable to extract an abstract from $filename. Please add the following comment to the file with your abstract:
    # ABSTRACT: turns baubles into trinkets
";
    }

    return $abstract;
  }
);

#pod =attr main_module
#pod
#pod This is the module where Dist::Zilla might look for various defaults, like
#pod the distribution abstract.  By default, it's derived from the distribution
#pod name.  If your distribution is Foo-Bar, and F<lib/Foo/Bar.pm> exists,
#pod that's the main_module.  Otherwise, it's the shortest-named module in the
#pod distribution.  This may change!
#pod
#pod You can override the default by specifying the file path explicitly,
#pod ie:
#pod
#pod   main_module = lib/Foo/Bar.pm
#pod
#pod =cut

has _main_module_override => (
  isa => 'Str',
  is  => 'ro' ,
  init_arg  => 'main_module',
  predicate => '_has_main_module_override',
);

has main_module => (
  is   => 'ro',
  isa  => 'Dist::Zilla::Role::File',
  lazy => 1,
  init_arg => undef,
  default  => sub {
    my ($self) = @_;

    my $file;
    my $guess;

    if ( $self->_has_main_module_override ) {
       $file = first { $_->name eq $self->_main_module_override }
               @{ $self->files };
    } else {
      # We're having to guess

      $guess = $self->name =~ s{-}{/}gr;
      $guess = "lib/$guess.pm";

      $file = (first { $_->name eq $guess } @{ $self->files })
          ||  (sort { length $a->name <=> length $b->name }
               grep { $_->name =~ m{\.pm\z} and $_->name =~ m{\Alib/} }
               @{ $self->files })[0];
      $self->log("guessing dist's main_module is " . ($file ? $file->name : $guess));
    }

    if (not $file) {
      my @errorlines;

      push @errorlines, "Unable to find main_module in the distribution";
      if ($self->_has_main_module_override) {
        push @errorlines, "'main_module' was specified in dist.ini but the file '" . $self->_main_module_override . "' is not to be found in our dist. ( Did you add it? )";
      } else {
        push @errorlines,"We tried to guess '$guess' but no file like that existed";
      }
      if (not @{ $self->files }) {
        push @errorlines, "Upon further inspection we didn't find any files in your dist, did you add any?";
      } elsif ( none { $_->name =~ m{^lib/.+\.pm\z} } @{ $self->files } ){
        push @errorlines, "We didn't find any .pm files in your dist, this is probably a problem.";
      }
      push @errorlines,"Cannot continue without a main_module";
      $self->log_fatal( join qq{\n}, @errorlines );
    }
    $self->log_debug("dist's main_module is " . $file->name);

    return $file;
  },
);

#pod =attr license
#pod
#pod This is the L<Software::License|Software::License> object for this dist's
#pod license and copyright.
#pod
#pod It will be created automatically, if possible, with the
#pod C<copyright_holder> and C<copyright_year> attributes.  If necessary, it will
#pod try to guess the license from the POD of the dist's main module.
#pod
#pod A better option is to set the C<license> name in the dist's config to something
#pod understandable, like C<Perl_5>.
#pod
#pod =cut

has license => (
  is   => 'ro',
  isa  => License,
  lazy => 1,
  init_arg  => 'license_obj',
  predicate => '_has_license',
  builder   => '_build_license',
  handles   => {
    copyright_holder => 'holder',
    copyright_year   => 'year',
  },
);

sub _build_license {
  my ($self) = @_;

  my $license_class    = $self->_license_class;
  my $copyright_holder = $self->_copyright_holder;
  my $copyright_year   = $self->_copyright_year;

  my $provided_license;

  for my $plugin (@{ $self->plugins_with(-LicenseProvider) }) {
    my $this_license = $plugin->provide_license({
      copyright_holder => $copyright_holder,
      copyright_year   => $copyright_year,
    });

    next unless defined $this_license;

    $self->log_fatal('attempted to set license twice')
      if defined $provided_license;

    $provided_license = $this_license;
  }

  return $provided_license if defined $provided_license;

  if ($license_class) {
    $license_class = String::RewritePrefix->rewrite(
      {
        '=' => '',
        ''  => 'Software::License::'
      },
      $license_class,
    );
  } else {
    require Software::LicenseUtils;
    my @guess = Software::LicenseUtils->guess_license_from_pod(
      $self->main_module->content
    );

    if (@guess != 1) {
      $self->log_fatal(
        "no license data in config, no %Rights stash,",
        "couldn't make a good guess at license from Pod; giving up. ",
        "Perhaps you need to set up a global config file (dzil setup)?"
      );
    }

    my $filename = $self->main_module->name;
    $license_class = $guess[0];
    $self->log("based on POD in $filename, guessing license is $guess[0]");
  }

  unless (eval { require_module($license_class) }) {
    $self->log_fatal(
      "could not load class $license_class for license " . $self->_license_class
    );
  }

  my $license = $license_class->new({
    holder  => $self->_copyright_holder,
    year    => $self->_copyright_year,
    program => $self->name,
  });

  $self->_clear_license_class;
  $self->_clear_copyright_holder;
  $self->_clear_copyright_year;

  return $license;
}

has _license_class => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  lazy      => 1,
  init_arg  => 'license',
  clearer   => '_clear_license_class',
  default   => sub {
    my $stash = $_[0]->stash_named('%Rights');
    $stash && return $stash->license_class;
    return;
  }
);

has _copyright_holder => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  lazy      => 1,
  init_arg  => 'copyright_holder',
  clearer   => '_clear_copyright_holder',
  default   => sub {
    return unless my $stash = $_[0]->stash_named('%Rights');
    $stash && return $stash->copyright_holder;
    return;
  }
);

has _copyright_year => (
  is        => 'ro',
  isa       => 'Str',
  lazy      => 1,
  init_arg  => 'copyright_year',
  clearer   => '_clear_copyright_year',
  default   => sub {
    # Oh man.  This is a terrible idea!  I mean, what if by the code gets run
    # around like Dec 31, 23:59:59.9 and by the time the default gets called
    # it's the next year but the default was already set up?  Oh man.  That
    # could ruin lives!  I guess we could make this a sub to defer the guess,
    # but think of the performance hit!  I guess we'll have to suffer through
    # this until we can optimize the code to not take .1s to run, right? --
    # rjbs, 2008-06-13
    my $stash = $_[0]->stash_named('%Rights');
    my $year  = $stash && $stash->copyright_year;
    return( $year // (localtime)[5] + 1900 );
  }
);

#pod =attr authors
#pod
#pod This is an arrayref of author strings, like this:
#pod
#pod   [
#pod     'Ricardo Signes <rjbs@cpan.org>',
#pod     'X. Ample, Jr <example@example.biz>',
#pod   ]
#pod
#pod This is likely to change at some point in the near future.
#pod
#pod =cut

has authors => (
  is   => 'ro',
  isa  => ArrayRef[Str],
  lazy => 1,
  default  => sub {
    my ($self) = @_;

    if (my $stash  = $self->stash_named('%User')) {
      return $stash->authors;
    }

    my $author = try { $self->copyright_holder };
    return [ $author ] if length $author;

    $self->log_fatal(
      "No %User stash and no copyright holder;",
      "can't determine dist author; configure author or a %User section",
    );
  },
);

#pod =attr files
#pod
#pod This is an arrayref of objects implementing L<Dist::Zilla::Role::File> that
#pod will, if left in this arrayref, be built into the dist.
#pod
#pod Non-core code should avoid altering this arrayref, but sometimes there is not
#pod other way to change the list of files.  In the future, the representation used
#pod for storing files B<will be changed>.
#pod
#pod =cut

has files => (
  is   => 'ro',
  isa  => ArrayRef[ role_type('Dist::Zilla::Role::File') ],
  lazy => 1,
  init_arg => undef,
  default  => sub { [] },
);

sub prune_file {
  my ($self, $file) = @_;
  my @files = @{ $self->files };

  for my $i (0 .. $#files) {
    next unless $file == $files[ $i ];
    splice @{ $self->files }, $i, 1;
    return;
  }

  return;
}

#pod =attr root
#pod
#pod This is the root directory of the dist, as a L<Path::Tiny>.  It will
#pod nearly always be the current working directory in which C<dzil> was run.
#pod
#pod =cut

has root => (
  is   => 'ro',
  isa  => Path,
  coerce   => 1,
  required => 1,
);

#pod =attr is_trial
#pod
#pod This attribute tells us whether or not the dist will be a trial release,
#pod i.e. whether it has C<release_status> 'testing' or 'unstable'.
#pod
#pod Do not set this directly, it will be derived from C<release_status>.
#pod
#pod =cut

has is_trial => (
  is => 'ro',
  isa => Bool,
  init_arg => undef,
  lazy => 1,
  builder => '_build_is_trial',
);

has _override_is_trial => (
  is => 'ro',
  isa => Bool,
  init_arg => 'is_trial',
  default => 0,
);

sub _build_is_trial {
    my ($self) = @_;
    return $self->release_status =~ /\A(?:testing|unstable)\z/ ? 1 : 0;
}

#pod =attr plugins
#pod
#pod This is an arrayref of plugins that have been plugged into this Dist::Zilla
#pod object.
#pod
#pod Non-core code B<must not> alter this arrayref.  Public access to this attribute
#pod B<may go away> in the future.
#pod
#pod =cut

has plugins => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::Plugin]',
  init_arg => undef,
  default  => sub { [ ] },
);

#pod =attr distmeta
#pod
#pod This is a hashref containing the metadata about this distribution that will be
#pod stored in META.yml or META.json.  You should not alter the metadata in this
#pod hash; use a MetaProvider plugin instead.
#pod
#pod =cut

has distmeta => (
  is   => 'ro',
  isa  => 'HashRef',
  init_arg  => undef,
  lazy      => 1,
  builder   => '_build_distmeta',
);

sub _build_distmeta {
  my ($self) = @_;

  require CPAN::Meta::Merge;
  my $meta_merge = CPAN::Meta::Merge->new(default_version => 2);
  my $meta = {};

  for (@{ $self->plugins_with(-MetaProvider) }) {
    $meta = $meta_merge->merge($meta, $_->metadata);
  }

  my %meta_main = (
    'meta-spec' => {
      version => 2,
      url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
    },
    name     => $self->name,
    version  => $self->version,
    abstract => $self->abstract,
    author   => $self->authors,
    license  => [ $self->license->meta2_name ],

    release_status => $self->release_status,

    dynamic_config => 0, # problematic, I bet -- rjbs, 2010-06-04
    generated_by   => $self->_metadata_generator_id
                    . ' version '
                    . ($self->VERSION // '(undef)'),
    x_generated_by_perl => "$^V", # v5.24.0
  );
  if (my $spdx = $self->license->spdx_expression) {
    $meta_main{x_spdx_expression} = $spdx;
  }

  $meta = $meta_merge->merge($meta, \%meta_main);

  return $meta;
}

sub _metadata_generator_id { 'Dist::Zilla' }

#pod =attr prereqs
#pod
#pod This is a L<Dist::Zilla::Prereqs> object, which is a thin layer atop
#pod L<CPAN::Meta::Prereqs>, and describes the distribution's prerequisites.
#pod
#pod =method register_prereqs
#pod
#pod Allows registration of prerequisites; delegates to
#pod L<Dist::Zilla::Prereqs/register_prereqs> via our L</prereqs> attribute.
#pod
#pod =cut

has prereqs => (
  is   => 'ro',
  isa  => 'Dist::Zilla::Prereqs',
  init_arg => undef,
  lazy     => 1,
  default  => sub { Dist::Zilla::Prereqs->new },
  handles  => [ qw(register_prereqs) ],
);

#pod =method plugin_named
#pod
#pod   my $plugin = $zilla->plugin_named( $plugin_name );
#pod
#pod =cut

sub plugin_named {
  my ($self, $name) = @_;
  my $plugin = first { $_->plugin_name eq $name } @{ $self->plugins };

  return $plugin if $plugin;
  return;
}

#pod =method plugins_with
#pod
#pod   my $roles = $zilla->plugins_with( -SomeRole );
#pod
#pod This method returns an arrayref containing all the Dist::Zilla object's plugins
#pod that perform the named role.  If the given role name begins with a dash, the
#pod dash is replaced with "Dist::Zilla::Role::"
#pod
#pod =cut

sub plugins_with {
  my ($self, $role) = @_;

  $role =~ s/^-/Dist::Zilla::Role::/;
  my $plugins = [ grep { $_->does($role) } @{ $self->plugins } ];

  return $plugins;
}

#pod =method find_files
#pod
#pod   my $files = $zilla->find_files( $finder_name );
#pod
#pod This method will look for a
#pod L<FileFinder|Dist::Zilla::Role::FileFinder>-performing plugin with the given
#pod name and return the result of calling C<find_files> on it.  If no plugin can be
#pod found, an exception will be raised.
#pod
#pod =cut

sub find_files {
  my ($self, $finder_name) = @_;

  $self->log_fatal("no plugin named $finder_name found")
    unless my $plugin = $self->plugin_named($finder_name);

  $self->log_fatal("plugin $finder_name is not a FileFinder")
    unless $plugin->does('Dist::Zilla::Role::FileFinder');

  $plugin->find_files;
}

sub _check_dupe_files {
  my ($self) = @_;

  my %files_named;
  my @dupes;
  for my $file (@{ $self->files }) {
    my $filename = $file->name;
    if (my $seen = $files_named{ $filename }) {
      push @{ $seen }, $file;
      push @dupes, $filename if @{ $seen } == 2;
    } else {
      $files_named{ $filename } = [ $file ];
    }
  }

  return unless @dupes;

  for my $name (@dupes) {
    $self->log("attempt to add $name multiple times; added by: "
       . join('; ', map { $_->added_by } @{ $files_named{ $name } })
    );
  }

  Carp::croak("aborting; duplicate files would be produced");
}

sub _write_out_file {
  my ($self, $file, $build_root) = @_;

  # Okay, this is a bit much, until we have ->debug. -- rjbs, 2008-06-13
  # $self->log("writing out " . $file->name);

  my $file_path = path($file->name);

  my $to_dir = path($build_root)->child( $file_path->parent );
  my $to = $to_dir->child( $file_path->basename );
  $to_dir->mkpath unless -e $to_dir;
  die "not a directory: $to_dir" unless -d $to_dir;

  Carp::croak("attempted to write $to multiple times") if -e $to;

  path("$to")->spew_raw( $file->encoded_content );
  chmod $file->mode, "$to" or die "couldn't chmod $to: $!";
}

#pod =attr logger
#pod
#pod This attribute stores a L<Log::Dispatchouli::Proxy> object, used to log
#pod messages.  By default, a proxy to the dist's L<Chrome|Dist::Zilla::Role::Chrome> is
#pod taken.
#pod
#pod The following methods are delegated from the Dist::Zilla object to the logger:
#pod
#pod =for :list
#pod * log
#pod * log_debug
#pod * log_fatal
#pod
#pod =cut

has logger => (
  is   => 'ro',
  isa  => 'Log::Dispatchouli::Proxy', # could be duck typed, I guess
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->chrome->logger->proxy({ proxy_prefix => '[DZ] ' })
  },
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;
  $config->{is_trial} = $self->is_trial;
  return $config;
};

has _local_stashes => (
  is   => 'ro',
  isa  => HashRef[ Object ],
  lazy => 1,
  default => sub { {} },
);

has _global_stashes => (
  is   => 'ro',
  isa  => HashRef[ Object ],
  lazy => 1,
  default => sub { {} },
);

#pod =method stash_named
#pod
#pod   my $stash = $zilla->stash_named( $name );
#pod
#pod This method will return the stash with the given name, or undef if none exists.
#pod It looks for a local stash (for this dist) first, then falls back to a global
#pod stash (from the user's global configuration).
#pod
#pod =cut

sub stash_named {
  my ($self, $name) = @_;

  return $self->_local_stashes->{ $name } if $self->_local_stashes->{$name};
  return $self->_global_stashes->{ $name };
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 STABILITY PROMISE
#pod
#pod None.
#pod
#pod I will try not to break things within any major release.  Minor releases are
#pod not extensively tested before release.  In major releases, anything goes,
#pod although I will try to publish a complete list of known breaking changes in any
#pod major release.
#pod
#pod If Dist::Zilla was a tool, it would have yellow and black stripes and there
#pod would be no L<UL
#pod certification|https://en.wikipedia.org/wiki/UL_(safety_organization)> on it.
#pod It is nasty, brutish, and large.
#pod
#pod =head1 SUPPORT
#pod
#pod There are usually people on C<irc.perl.org> in C<#distzilla>, even if they're
#pod idling.
#pod
#pod The L<Dist::Zilla website|https://dzil.org/> has several valuable resources for
#pod learning to use Dist::Zilla.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod In the Dist::Zilla distribution:
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod Plugin bundles:
#pod L<@Basic|Dist::Zilla::PluginBundle::Basic>,
#pod L<@Filter|Dist::Zilla::PluginBundle::Filter>.
#pod
#pod =item *
#pod
#pod Major plugins:
#pod L<GatherDir|Dist::Zilla::Plugin::GatherDir>,
#pod L<Prereqs|Dist::Zilla::Plugin::Prereqs>,
#pod L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>,
#pod L<MetaYAML|Dist::Zilla::Plugin::MetaYAML>,
#pod L<MetaJSON|Dist::Zilla::Plugin::MetaJSON>,
#pod ...
#pod
#pod =back
#pod
#pod =item *
#pod
#pod On the CPAN:
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod Search for plugins: L<https://metacpan.org/search?q=Dist::Zilla::Plugin::>
#pod
#pod =item *
#pod
#pod Search for plugin bundles: L<https://metacpan.org/search?q=Dist::Zilla::PluginBundle::>
#pod
#pod =back
#pod
#pod =back

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla - distribution builder; installer not included!

=head1 VERSION

version 6.032

=head1 DESCRIPTION

Dist::Zilla builds distributions of code to be uploaded to the CPAN.  In this
respect, it is like L<ExtUtils::MakeMaker>, L<Module::Build>, or
L<Module::Install>.  Unlike those tools, however, it is not also a system for
installing code that has been downloaded from the CPAN.  Since it's only run by
authors, and is meant to be run on a repository checkout rather than on
published, released code, it can do much more than those tools, and is free to
make much more ludicrous demands in terms of prerequisites.

If you have access to the web, you can learn more and find an interactive
tutorial at B<L<dzil.org|https://dzil.org/>>.  If not, try
L<Dist::Zilla::Tutorial>.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 name

The name attribute (which is required) gives the name of the distribution to be
built.  This is usually the name of the distribution's main module, with the
double colons (C<::>) replaced with dashes.  For example: C<Dist-Zilla>.

=head2 version

This is the version of the distribution to be created.

=head2 release_status

This attribute sets the release status to one of the
L<CPAN::META::Spec|https://metacpan.org/pod/CPAN::Meta::Spec#release_status>
values: 'stable', 'testing' or 'unstable'.

If the C<$ENV{RELEASE_STATUS}> environment variable exists, its value will
be used as the release status.

For backwards compatibility, if C<$ENV{RELEASE_STATUS}> does not exist and
the C<$ENV{TRIAL}> variable is true, the release status will be 'testing'.

Otherwise, the release status will be set from a
L<ReleaseStatusProvider|Dist::Zilla::Role::ReleaseStatusProvider>, if one
has been configured.

For backwards compatibility, setting C<is_trial> true in F<dist.ini> is
equivalent to using a C<ReleaseStatusProvider>.  If C<is_trial> is false,
it has no effect.

Only B<one> C<ReleaseStatusProvider> may be used.

If no providers are used, the release status defaults to 'stable' unless there
is an "_" character in the version, in which case, it defaults to 'testing'.

=head2 abstract

This is a one-line summary of the distribution.  If none is given, one will be
looked for in the L</main_module> of the dist.

=head2 main_module

This is the module where Dist::Zilla might look for various defaults, like
the distribution abstract.  By default, it's derived from the distribution
name.  If your distribution is Foo-Bar, and F<lib/Foo/Bar.pm> exists,
that's the main_module.  Otherwise, it's the shortest-named module in the
distribution.  This may change!

You can override the default by specifying the file path explicitly,
ie:

  main_module = lib/Foo/Bar.pm

=head2 license

This is the L<Software::License|Software::License> object for this dist's
license and copyright.

It will be created automatically, if possible, with the
C<copyright_holder> and C<copyright_year> attributes.  If necessary, it will
try to guess the license from the POD of the dist's main module.

A better option is to set the C<license> name in the dist's config to something
understandable, like C<Perl_5>.

=head2 authors

This is an arrayref of author strings, like this:

  [
    'Ricardo Signes <rjbs@cpan.org>',
    'X. Ample, Jr <example@example.biz>',
  ]

This is likely to change at some point in the near future.

=head2 files

This is an arrayref of objects implementing L<Dist::Zilla::Role::File> that
will, if left in this arrayref, be built into the dist.

Non-core code should avoid altering this arrayref, but sometimes there is not
other way to change the list of files.  In the future, the representation used
for storing files B<will be changed>.

=head2 root

This is the root directory of the dist, as a L<Path::Tiny>.  It will
nearly always be the current working directory in which C<dzil> was run.

=head2 is_trial

This attribute tells us whether or not the dist will be a trial release,
i.e. whether it has C<release_status> 'testing' or 'unstable'.

Do not set this directly, it will be derived from C<release_status>.

=head2 plugins

This is an arrayref of plugins that have been plugged into this Dist::Zilla
object.

Non-core code B<must not> alter this arrayref.  Public access to this attribute
B<may go away> in the future.

=head2 distmeta

This is a hashref containing the metadata about this distribution that will be
stored in META.yml or META.json.  You should not alter the metadata in this
hash; use a MetaProvider plugin instead.

=head2 prereqs

This is a L<Dist::Zilla::Prereqs> object, which is a thin layer atop
L<CPAN::Meta::Prereqs>, and describes the distribution's prerequisites.

=head2 logger

This attribute stores a L<Log::Dispatchouli::Proxy> object, used to log
messages.  By default, a proxy to the dist's L<Chrome|Dist::Zilla::Role::Chrome> is
taken.

The following methods are delegated from the Dist::Zilla object to the logger:

=over 4

=item *

log

=item *

log_debug

=item *

log_fatal

=back

=head1 METHODS

=head2 register_prereqs

Allows registration of prerequisites; delegates to
L<Dist::Zilla::Prereqs/register_prereqs> via our L</prereqs> attribute.

=head2 plugin_named

  my $plugin = $zilla->plugin_named( $plugin_name );

=head2 plugins_with

  my $roles = $zilla->plugins_with( -SomeRole );

This method returns an arrayref containing all the Dist::Zilla object's plugins
that perform the named role.  If the given role name begins with a dash, the
dash is replaced with "Dist::Zilla::Role::"

=head2 find_files

  my $files = $zilla->find_files( $finder_name );

This method will look for a
L<FileFinder|Dist::Zilla::Role::FileFinder>-performing plugin with the given
name and return the result of calling C<find_files> on it.  If no plugin can be
found, an exception will be raised.

=head2 stash_named

  my $stash = $zilla->stash_named( $name );

This method will return the stash with the given name, or undef if none exists.
It looks for a local stash (for this dist) first, then falls back to a global
stash (from the user's global configuration).

=head1 STABILITY PROMISE

None.

I will try not to break things within any major release.  Minor releases are
not extensively tested before release.  In major releases, anything goes,
although I will try to publish a complete list of known breaking changes in any
major release.

If Dist::Zilla was a tool, it would have yellow and black stripes and there
would be no L<UL
certification|https://en.wikipedia.org/wiki/UL_(safety_organization)> on it.
It is nasty, brutish, and large.

=head1 SUPPORT

There are usually people on C<irc.perl.org> in C<#distzilla>, even if they're
idling.

The L<Dist::Zilla website|https://dzil.org/> has several valuable resources for
learning to use Dist::Zilla.

=head1 SEE ALSO

=over 4

=item *

In the Dist::Zilla distribution:

=over 4

=item *

Plugin bundles:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<@Filter|Dist::Zilla::PluginBundle::Filter>.

=item *

Major plugins:
L<GatherDir|Dist::Zilla::Plugin::GatherDir>,
L<Prereqs|Dist::Zilla::Plugin::Prereqs>,
L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>,
L<MetaYAML|Dist::Zilla::Plugin::MetaYAML>,
L<MetaJSON|Dist::Zilla::Plugin::MetaJSON>,
...

=back

=item *

On the CPAN:

=over 4

=item *

Search for plugins: L<https://metacpan.org/search?q=Dist::Zilla::Plugin::>

=item *

Search for plugin bundles: L<https://metacpan.org/search?q=Dist::Zilla::PluginBundle::>

=back

=back

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Ævar Arnfjörð Bjarmason Alastair McGowan-Douglas Alceu Rodrigues de Freitas Junior Alexei Znamensky Alex Vandiver ambs Andrew Rodland Andy Jack Apocalypse ben hengst Bernardo Rechea Branislav Zahradník Brian Fraser Caleb Cushing Chase Whitener Chisel Christian Walde Christopher Bottoms J. Madsen Chris Weyl Cory G Watson csjewell Curtis Brandt Dagfinn Ilmari Mannsåker Damien KRotkine Dan Book Daniel Böhmer Danijel Tasov Dave Lambley O'Neill Rolsky David E. Wheeler Golden H. Adler Steinbrunner Zurborg Davor Cubranic Dimitar Petrov Doug Bell Elvin Aslanov Erik Carlsson Fayland Lam Felix Ostmann Florian Ragwitz Fred Moyer fREW Schmidt gardnerm Gianni Ceccarelli Graham Barr Knop Ollis Grzegorz Rożniecki Håkon Hægland Hans Dieter Pearcey Hunter McMillen Ivan Bessarabov Jakob Voss jantore Jérôme Quelin Jesse Luehrs Vincent JJ Merelo John Napiorkowski jonasbn Jonathan C. Otsuka Rockway Scott Duff Yu Karen Etheridge Kent Fredric Leon Timmermans Lucas Theisen Luc St-Louis Marcel Gruenauer Mark Flickinger Martin McGrath Mary Ehlers Mateu X Matthew Horsfall mauke Michael Conrad G. Schwern Jemmeson Mickey Nasriachi Mike Doherty Mohammad S Anwar Moritz Onken Neil Bowers Nickolay Platonov Nick Tonkin nperez Olivier Mengué Paul Cochrane Paulo Custodio Pedro Melo perlancar (@pc-office) Philippe Bruhat (BooK) raf Randy Stauner reneeb Ricardo Signes robertkrimen Rob Hoelz Robin Smidsrød Roy Ivy III Shawn M Moore Shlomi Fish Shoichi Kaji Smylers Steffen Schwigon Steven Haryanto Tatsuhiko Miyagawa Upasana Shukla Van Bugger Vyacheslav Matjukhin Yanick Champoux Yuval Kogman

=over 4

=item *

Ævar Arnfjörð Bjarmason <avarab@gmail.com>

=item *

Alastair McGowan-Douglas <alastair.mcgowan@opusvl.com>

=item *

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=item *

Alexei Znamensky <russoz@cpan.org>

=item *

Alex Vandiver <alexmv@mit.edu>

=item *

ambs <ambs@cpan.org>

=item *

Andrew Rodland <andrew@hbslabs.com>

=item *

Andy Jack <andyjack@cpan.org>

=item *

Apocalypse <APOCAL@cpan.org>

=item *

ben hengst <ben.hengst@gmail.com>

=item *

Bernardo Rechea <brbpub@gmail.com>

=item *

Branislav Zahradník <happy.barney@gmail.com>

=item *

Brian Fraser <fraserbn@gmail.com>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Chase Whitener <cwhitener@gmail.com>

=item *

Chisel <chisel@chizography.net>

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

Christopher Bottoms <molecules@users.noreply.github.com>

=item *

Christopher J. Madsen <cjm@cjmweb.net>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=item *

Cory G Watson <gphat@onemogin.com>

=item *

csjewell <perl@csjewell.fastmail.us>

=item *

Curtis Brandt <curtisjbrandt@gmail.com>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Damien KRotkine <dkrotkine@booking.com>

=item *

Dan Book <grinnz@gmail.com>

=item *

Daniel Böhmer <post@daniel-boehmer.de>

=item *

Danijel Tasov <dt@korn.shell.la>

=item *

Dave Lambley <dave@lambley.me.uk>

=item *

Dave O'Neill <dmo@dmo.ca>

=item *

Dave Rolsky <autarch@urth.org>

=item *

David E. Wheeler <david@justatheory.com>

=item *

David Golden <dagolden@cpan.org>

=item *

David H. Adler <dha@pobox.com>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

David Zurborg <port@david-zurb.org>

=item *

Davor Cubranic <cubranic@stat.ubc.ca>

=item *

Dimitar Petrov <mitakaa@gmail.com>

=item *

Doug Bell <doug@preaction.me>

=item *

Doug Bell <madcityzen@gmail.com>

=item *

Elvin Aslanov <rwp.primary@gmail.com>

=item *

Erik Carlsson <info@code301.com>

=item *

Fayland Lam <fayland@gmail.com>

=item *

Felix Ostmann <felix.ostmann@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Fred Moyer <fred@redhotpenguin.com>

=item *

fREW Schmidt <frioux@gmail.com>

=item *

gardnerm <gardnerm@gsicommerce.com>

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Graham Barr <gbarr@pobox.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Graham Ollis <perl@wdlabs.com>

=item *

Graham Ollis <plicease@cpan.org>

=item *

Grzegorz Rożniecki <xaerxess@gmail.com>

=item *

Håkon Hægland <hakon.hagland@gmail.com>

=item *

Hans Dieter Pearcey <hdp@weftsoar.net>

=item *

Hunter McMillen <mcmillhj@gmail.com>

=item *

Ivan Bessarabov <ivan@bessarabov.ru>

=item *

Jakob Voss <jakob@nichtich.de>

=item *

jantore <jantore@32k.org>

=item *

Jérôme Quelin <jquelin@gmail.com>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

JJ Merelo <jjmerelo@gmail.com>

=item *

John Napiorkowski <jjnapiork@cpan.org>

=item *

jonasbn <jonasbn@gmail.com>

=item *

Jonathan C. Otsuka <djgoku@gmail.com>

=item *

Jonathan Rockway <jrockway@cpan.org>

=item *

Jonathan Scott Duff <duff@pobox.com>

=item *

Jonathan Yu <jawnsy@cpan.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Kent Fredric <kentnl@gentoo.org>

=item *

Leon Timmermans <fawaka@gmail.com>

=item *

Lucas Theisen <lucastheisen@pastdev.com>

=item *

Luc St-Louis <lucs@pobox.com>

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=item *

Mark Flickinger <mark.flickinger@grantstreet.com>

=item *

Martin McGrath <mcgrath.martin@gmail.com>

=item *

Mary Ehlers <regina.verb.ae@gmail.com>

=item *

Mateu X Hunter <hunter@missoula.org>

=item *

Matthew Horsfall <wolfsage@gmail.com>

=item *

mauke <l.mai@web.de>

=item *

Michael Conrad <mike@nrdvana.net>

=item *

Michael G. Schwern <schwern@pobox.com>

=item *

Michael Jemmeson <mjemmeson@cpan.org>

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Mike Doherty <mike@mikedoherty.ca>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Moritz Onken <onken@netcubed.de>

=item *

Neil Bowers <neil@bowers.com>

=item *

Nickolay Platonov <nickolay@desktop.(none)>

=item *

Nick Tonkin <1nickt@users.noreply.github.com>

=item *

nperez <nperez@cpan.org>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Paul Cochrane <paul@liekut.de>

=item *

Paulo Custodio <pauloscustodio@gmail.com>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

perlancar (@pc-office) <perlancar@gmail.com>

=item *

Philippe Bruhat (BooK) <book@cpan.org>

=item *

raf <68724930+rafork@users.noreply.github.com>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

reneeb <info@perl-services.de>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Robin Smidsrød <robin@smidsrod.no>

=item *

Roy Ivy III <rivy@cpan.org>

=item *

Shawn M Moore <sartak@gmail.com>

=item *

Shlomi Fish <shlomif@shlomifish.org>

=item *

Shoichi Kaji <skaji@cpan.org>

=item *

Smylers <Smylers@stripey.com>

=item *

Steffen Schwigon <ss5@renormalist.net>

=item *

Steven Haryanto <stevenharyanto@gmail.com>

=item *

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=item *

Upasana Shukla <me@upasana.me>

=item *

Van de Bugger <van.de.bugger@gmail.com>

=item *

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
