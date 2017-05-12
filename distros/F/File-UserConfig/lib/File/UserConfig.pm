package File::UserConfig;

=pod

=head1 NAME

File::UserConfig - Get a user's existing config directory, or copy in defaults

  # The most simple Do What I Mean usage.
  $configdir = File::UserConfig->configdir;
  
  # Or without taking advantage of convention-based defaults
  $configdir = File::UserConfig->new(
  	dist     => 'My-Application',
  	module   => 'My::Application',
  	dirname  => '.myapp',
  	sharedir => $defaults_here,
  	)->configdir;

=head1 DESCRIPTION

Many modules or applications maintain a user-spec configuration data
directory. And the implementation pattern is generally the same.

A directory like F</home/myuser/.application> is created and populating by
a set of default files the first time an application runs, and from there
on, the files in that directory are modified.

C<File::UserConfig> provides standard, light and sub-classable default
implementation of this concept that Does The Right Thing with the
directory names.

=head2 Applying Perl Conventions

C<File::UserConfig> applies and automates the following conventions.

B<1. We are using the distribution name?>

The use of C<File::ShareDir> is based on distribution name (more on that
later) so we need to know it.

The CPAN convention is for a dist to be named C<Foo-Bar> after the
main module C<Foo::Bar> in the distribution, but sometimes this
varies, and sometimes you will want to call C<File::UserConfig> from
other than the main module. But unless you say otherwise,
C<File::UserConfig> will assume that if you call it from "Module::Name",
that is probably the main module, and thus your dist is probably called
"Module-Name".

B<2. What config directory name is used>

On platforms which keep application-specific data in its own directory,
well away from the data the user actually create themself, we just use
the dist name.

On Unix, which has a combined home directory, we remap the dist name to
be a lowercase hidden name with all '-' chars as '_'.

So on unix only, "Module::Name" will become ".module_name". Most of the
time, this will end up what you would have used anyway.

B<3. Where does the config directory live>

C<File::UserConfig> knows where your home directory is by using
L<File::HomeDir>. And more specifically, on platforms that support
application data being kept in a subdirectory, it will use that as well.

On Unix, Windows, and Mac OS X, it will just Do The Right Thing.

B<4. Where do the defaults come from?>

The ability for a distribution to provide a directory full of default
files is provided in Perl by L<File::ShareDir>.

Of course, we're also assuming you are using L<Module::Install> so you
have access to its C<install_share> command, and that the only thing
your dist is going to install to it will be the default config dir.

=head1 METHODS

The 6 accessors all feature implicit constructors.

In other words, the two following lines are equivalent.

  # Explicitly
  $configdir = File::UserConfig->new( ... )->configdir;
  
  # Auto-construction
  $configdir = File::UserConfig->configdir( ... );
  
  # Thus, using all default params we can just
  $configdir = File::UserConfig->configdir;

=cut

use 5.005;
use strict;
use Carp                  ();
use File::Spec            ();
use File::Copy::Recursive ();
use File::HomeDir         ();
use File::ShareDir        ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.06';
}





#####################################################################
# Constructor

=pod

=head2 new

  my $config = File::UserConfig->new(
      dist      => 'Not-This-Class',
      dirname   => '.myconfig',
      sharedir  => 'defaultconfig',
      homedir   => $username,
      );

The C<new> constructor takes a set of optional named params, and finds
the user's configuration directory, creating it by copying in a default
directory if an existing one cannot be found.

In almost every case, you will want to use all the defaults and let
everything be determined automatically for you. The sample above tries
to show some of the limited number of situations in which you might want
to consider providing your own values.

But most times, you don't want to or need to. Try it without params
first, and add some params if it isn't working for you.

If you want to do some custom actions after you copy in the directory,
the subclass and add it after you call the parent C<new> method.

Returns a new C<File::UserConfig> object, or dies on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# If we don't have a dist, use the caller.
	unless ( $self->dist ) {
		# Guess from the caller
		$self->{dist} = $self->_caller;
		$self->{dist} =~ s/::/-/;
	}

	# If we don't have a module, use the caller
	unless ( $self->module ) {
		# Guess from the caller
		$self->{module} = $self->_caller;
	}

	# If we don't have a sharedir, get it
	# from the dist.
	unless ( $self->sharedir ) {
		$self->{sharedir} = File::ShareDir::dist_dir($self->dist);
	}

	# If we don't have a directory name, derive one
	unless ( $self->dirname ) {
		# Derive from the caller based on HomeDir naming scheme
		my $scheme = $File::HomeDir::IMPLEMENTED_BY
			or die "Failed to find File::HomeDir naming scheme";
		if ( $scheme->isa('File::HomeDir::Darwin') ) {
			# Keep the same
			$self->{dirname} = $self->dist;
		} elsif ( $scheme->isa('File::HomeDir::Windows') ) {
			# Keep the same
			$self->{dirname} = $self->dist;
		} elsif ( $scheme->isa('File::HomeDir::Unix') ) {
			$self->{dirname} = '.' . lc $self->dist; # Hidden lowercase
			$self->{dirname} =~ s/-/_/g;             # Foo-Bar -> .foo_bar
		} else {
			die "Unsupported HomeDir naming scheme $scheme";
		}
	}

	# Find the config dir
	unless ( $self->configdir ) {
		unless ( $self->homedir ) {
			$self->{homedir} = File::HomeDir->my_data;
		}
		$self->{configdir} = File::Spec->catdir(
			$self->homedir, $self->dirname,
			);
	}

	# Does the config directory already exist?
	if ( -d $self->configdir ) {
		# Shortcut and return
		return $self;
	} elsif ( -f $self->configdir ) {
		my $configdir = $self->configdir;
		Carp::croak("Existing file $configdir is blocking creation of config directory");
	}

	# Copy in the files from the sharedir
	File::Copy::Recursive::dircopy( $self->sharedir, $self->configdir )
		or Carp::croak("Failed to copy user data to " . $self->configdir);

	$self;
}

=pod

=head2 dist

  $name = File::UserConfig->new(...)->dist;
  
  $name = File::UserConfig->dist(...);

The C<dist> accessor returns the name of the distribution.

=cut

sub dist {
	my $self = ref $_[0] ? shift : shift()->new(@_);
	$self->{dist};
}

=pod

=head2 module

  $name = File::UserConfig->new(...)->module;
  
  $name = File::UserConfig->module(...);

The C<module> accessor returns the name of the module.

Although the default dirname is based off the dist name, the module
name is the one used to find the shared dir.

=cut

sub module {
	my $self = ref $_[0] ? shift : shift()->new(@_);
	$self->{module};
}

=pod

=head2 dirname

  $dir = File::UserConfig->new(...)->dirname;
  
  $dir = File::UserConfig->dirname(...);

The C<dirname> accessor returns the name to be used for the config
directory name, below the homedir. For example C<'.foo_bar'>.

=cut

sub dirname {
	my $self = ref $_[0] ? shift : shift()->new(@_);
	$self->{dirname};
}

=pod

=head2 sharedir

  $dir = File::UserConfig->new(...)->sharedir;
  
  $dist = File::UserConfig->sharedir(...);

The C<sharedir> accessor returns the name of the directory where the
shared default configuration is held.

Returns a path string, verified to exist before being returned.

=cut

sub sharedir {
	my $self = ref $_[0] ? shift : shift()->new(@_);
	$self->{sharedir};
}

=pod

=head2 homedir

  $dir = File::UserConfig->new(...)->homedir;
  
  $dist = File::UserConfig->homedir(...);

The C<homedir> accessor returns the location of the home direcotry, that
the config dir will be created or found below.

Returns a path string, verified to exist before being returned.

=cut

sub homedir {
	my $self = ref $_[0] ? shift : shift()->new(@_);
	$self->{homedir};
}

=pod

=head2 configdir

  $dir = File::UserConfig->new(...)->configdir;
  
  $dist = File::UserConfig->configdir(...);

The C<sharedir> accessor returns the name of the directory where the
shared default configuration is held.

Returns a path string, verified to exist before being returned.

=cut

sub configdir {
	my $self = ref $_[0] ? shift : shift()->new(@_);
	$self->{configdir};	
}





#####################################################################
# Support Methods

sub _caller {
	my $i = 0;
	while ( my @c = caller($i++) ) {
		next if $c[0]->isa(__PACKAGE__);
		return $c[0];
	}
	die "Failed to find caller";
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-UserConfig>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<File::HomeDir>, L<File::ShareDir>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
