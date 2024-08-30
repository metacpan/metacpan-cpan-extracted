package File::XDG;

use strict;
use warnings;
use Carp ();
use Config;
use Ref::Util qw( is_coderef is_arrayref );
use if $^O eq 'MSWin32', 'Win32';

# ABSTRACT: Basic implementation of the XDG base directory specification
our $VERSION = '1.03'; # VERSION




sub new {
    my $class = shift;
    my %args = (@_);

    my $name = delete $args{name};
    Carp::croak('application name required') unless defined $name;

    my $api = delete $args{api};
    $api = 0 unless defined $api;
    Carp::croak("Unsupported api = $api") unless $api == 0 || $api == 1;

    my $path_class = delete $args{path_class};

    unless(defined $path_class) {
      if($api >= 1) {
        $path_class = 'Path::Tiny';
      } else {
        $path_class = 'Path::Class';
      }
    }

    my $file_class = $path_class eq 'Path::Class' ? 'Path::Class::File' : $path_class;
    my $dir_class  = $path_class eq 'Path::Class' ? 'Path::Class::Dir'  : $path_class;

    if(is_coderef($path_class))
    {
      $dir_class = $file_class = $path_class;
    }
    elsif(is_arrayref($path_class))
    {
      ($file_class, $dir_class) = @$path_class;
    }
    elsif($path_class eq 'Path::Tiny')
    {
      require Path::Tiny;
    }
    elsif($path_class eq 'Path::Class')
    {
      require Path::Class::File;
      require Path::Class::Dir;
    }
    elsif($path_class eq 'File::Spec')
    {
      require File::Spec;
      $file_class = sub { File::Spec->catfile(@_) };
      $dir_class  = sub { File::Spec->catdir(@_) };
    }
    else
    {
      Carp::croak("Unknown path class: $path_class");
    }

    my $strict = delete $args{strict};
    Carp::croak("XDG base directory specification cannot strictly implemented on Windows")
      if $^O eq 'MSWin32' && $strict;

    Carp::croak("unknown arguments: @{[ sort keys %args ]}") if %args;

    my $self = bless {
        name       => $name,
        api        => $api,
        file_class => $file_class,
        dir_class  => $dir_class,
        strict     => $strict,
        runtime    => $ENV{XDG_RUNTIME_DIR},
    }, $class;

    if($^O eq 'MSWin32') {
        my $local = Win32::GetFolderPath(Win32::CSIDL_LOCAL_APPDATA(), 1);
        $self->{home}        = $local;
        $self->{data}        = $ENV{XDG_DATA_HOME}   || "$local\\.local\\share\\";
        $self->{cache}       = $ENV{XDG_CACHE_HOME}  || "$local\\.cache\\";
        $self->{config}      = $ENV{XDG_CONFIG_HOME} || "$local\\.config\\";
        $self->{state}       = $ENV{XDG_STATE_HOME}  || "$local\\.local\\state\\";
        $self->{data_dirs}   = $ENV{XDG_DATA_DIRS}   || '';
        $self->{config_dirs} = $ENV{XDG_CONFIG_DIRS} || '';
    } else {
        my $home = $ENV{HOME} || [getpwuid($>)]->[7];
        $self->{home}        = $home;
        $self->{data}        = $ENV{XDG_DATA_HOME}   || "$home/.local/share/";
        $self->{cache}       = $ENV{XDG_CACHE_HOME}  || "$home/.cache/";
        $self->{state}       = $ENV{XDG_STATE_HOME}  || "$home/.local/state/";
        $self->{config}      = $ENV{XDG_CONFIG_HOME} || "$home/.config/";
        $self->{data_dirs}   = $ENV{XDG_DATA_DIRS}   || '/usr/local/share:/usr/share';
        $self->{config_dirs} = $ENV{XDG_CONFIG_DIRS} || '/etc/xdg';
    }

    return $self;
}

sub _dir {
  my $self = shift;
  is_coderef($self->{dir_class})
    ? $self->{dir_class}->(@_)
    : $self->{dir_class}->new(@_);
}

sub _file {
  my $self = shift;
  is_coderef($self->{dir_class})
    ? $self->{file_class}->(@_)
    : $self->{file_class}->new(@_);
}

sub _dirs {
    my($self, $type) = @_;
    return $self->{"${type}_dirs"} if exists $self->{"${type}_dirs"};
    Carp::croak('invalid _dirs requested');
}

sub _lookup_file {
    my ($self, $type, @subpath) = @_;

    Carp::croak('subpath not specified') unless @subpath;
    Carp::croak("invalid type: $type") unless defined $self->{$type};

    my @dirs = ($self->{$type}, split(/\Q$Config{path_sep}\E/, $self->_dirs($type)));
    my @paths = map { $self->_file($_, @subpath) } @dirs;
    my ($match) = grep { -f $_ } @paths;

    return $match;
}


sub data_home {
    my $self = shift;
    my $xdg = $self->{data};
    return $self->_dir($xdg, $self->{name});
}


sub config_home {
    my $self = shift;
    my $xdg = $self->{config};
    return $self->_dir($xdg, $self->{name});
}


sub cache_home {
    my $self = shift;
    my $xdg = $self->{cache};
    return $self->_dir($xdg, $self->{name});
}


sub state_home {
  my $self = shift;
  return $self->_dir($self->{state}, $self->{name});
}


sub runtime_home
{
  my($self) = @_;
  my $base = $self->_runtime_dir;
  defined $base ? $self->_dir($base, $self->{name}) : undef;
}

sub _runtime_dir
{
  my($self) = @_;
  if(defined $self->{runtime})
  {
    return $self->{runtime};
  }

  # the spec says only to look for the environment variable
  return undef if $self->{strict};

  my @maybe;

  if($^O eq 'linux')
  {
    push @maybe, "/run/user/$<";
  }

  foreach my $maybe (@maybe)
  {
    # if we are going rogue and trying to find the runtime dir
    # on our own, then we hould at least check that the directory
    # fufills the requirements of the spec: directory, owned by
    # us, with permission of 0700.
    next unless -d $maybe;
    next unless -o $maybe;
    my $perm = [stat $maybe]->[2] & oct('0777');
    next unless $perm == oct('0700');
    return $maybe;
  }

  return undef;
}


sub data_dirs {
    return shift->_dirs('data');
}


sub data_dirs_list {
    my $self = shift;
    return map { $self->_dir($_) } split /\Q$Config{path_sep}\E/, $self->data_dirs;
}


sub config_dirs {
    return shift->_dirs('config');
}


sub config_dirs_list {
    my $self = shift;
    return map { $self->_dir($_) } split /\Q$Config{path_sep}\E/, $self->config_dirs;
}


sub exe_dir
{
  my($self) = @_;
  -d "@{[ $self->{home} ]}/.local/bin"
  ? $self->_dir($self->{home}, '.local', 'bin')
  : undef;
}


sub lookup_data_file {
    my ($self, @subpath) = @_;
    unshift @subpath, $self->{name} if $self->{api} >= 1;
    return $self->_lookup_file('data', @subpath);
}


sub lookup_config_file {
    my ($self, @subpath) = @_;
    unshift @subpath, $self->{name} if $self->{api} >= 1;
    return $self->_lookup_file('config', @subpath);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::XDG - Basic implementation of the XDG base directory specification

=head1 VERSION

version 1.03

=head1 SYNOPSIS

 use File::XDG 1.00;
 
 my $xdg = File::XDG->new( name => 'foo', api => 1 );
 
 # user config
 my $path = $xdg->config_home;
 
 # user data
 my $path = $xdg->data_home;
 
 # user cache
 my $path = $xdg->cache_home;
 
 # system $config
 my @dirs = $xdg->config_dirs_list;
 
 # system data
 my @dirs = $xdg->data_dirs_list;

=head1 DESCRIPTION

This module provides a basic implementation of the XDG base directory
specification as exists by the Free Desktop Organization (FDO). It supports
all XDG directories except for the runtime directories, which require session
management support in order to function.

=head1 CONSTRUCTOR

=head2 new

 my $xdg = File::XDG->new( %args );

Returns a new instance of a L<File::XDG> object. This must be called with an
application name as the L</name> argument.

Takes the following named arguments:

=over 4

=item api

[version 0.09]

The API version to use.

=over 4

=item api = 0

The default and original API version.  For backward compatibility only.

=item api = 1

Recommended stable API version for all new code.

=back

=item name

Name of the application for which File::XDG is being used.

=item path_class

[version 0.09]

The path class to return

=over

=item L<File::Spec>

All methods that return a file will return a string generated by L<File::Spec>.

=item L<Path::Class>

This is the default with api = 0.  All methods that return a file will return
an instance of L<Path::Class::File> and all methods that return a directory will
return an instance of L<Path::Class::Dir>.

=item L<Path::Tiny>

This is the default with api = 1.  All methods that return a file will return
an instance of L<Path::Tiny>.

=item C<CODEREF>

If a code reference is passed in then this will be called in order to construct
the path class.  This allows rolling your own customer path class objects.
Example:

 my $xdg = File::XDG->new(
   name => 'foo',
   # equivalent to path_class => 'Path::Tiny'
   path_class => sub { Path::Tiny->new(@_),
 );

=item C<ARRAY>

Similar to passing a code reference, an array reference with two code references
means the first code reference will be used for file paths and the second will
be used for directory paths.  This is for path classes that differentiate
between files and directories.

 # equivalent to path_class => 'Path::Class'
 my $xdg = File::XDG->new(
   name => 'foo',
   path_class => [
     sub { Path::Class::File->new(@_) ),
     sub { Path::Class::Dir->new(@_) },
   ],
 );

=back

=item strict

[version 0.10]

More strictly follow the XDG base directory specification.  In particular

=over 4

=item

On Windows a an exception will be thrown when creating the L<File::XDG>
object because the spec cannot correctly be implemented.

Historically this module has made some useful assumptions like using
C<;> instead of C<:> for the path separator character.  This breaks the
spec.

=item

On some systems, this module will look in system specific locations for
the L</runtime_home>.  This is useful, but technically violates the spec,
so under strict mode the L</runtime_home> method will only return a path
if one can be found via the spec.

=back

=back

=head1 METHODS

=head2 data_home

 my $path = $xdg->data_home;

Returns the user-specific data directory for the application as a path class object.

=head2 config_home

 my $path = $xdg->config_home;

Returns the user-specific configuration directory for the application as a path class object.

=head2 cache_home

 my $path = $xdg->cache_home;

Returns the user-specific cache directory for the application as a path class object.

=head2 state_home

 my $path = $xdg->state_home;

Returns the user-specific state directory for the application as a path class object.

=head2 runtime_home

[version 0.10]

 my $dir = $xdg->runtime_home;

Returns the directory for user-specific non-essential runtime files and other file objects
(such as sockets, named pipes, etc) for the application.

This is not always provided, if not available, this method will return C<undef>.

Under strict mode, this method will only rely on the C<XDG_RUNTIME_DIR> to find this directory.
Under non-strict mode, system specific methods may be used, if the environment variable is not
set:

=over 4

=item Linux systemd

The path C</run/user/UID> will be used, if it exists, and fulfills the requirements of the spec.

=back

=head2 data_dirs

 my $dirs = $xdg->data_dirs;

Returns the system data directories, not modified for the application. Per the
specification, the returned string is C<:>-delimited, except on Windows where it
is C<;>-delimited.

For portability L</data_dirs_list> is preferred.

=head2 data_dirs_list

[version 0.06]

 my @dirs = $xdg->data_dirs_list;

Returns the system data directories as a list of path class objects.

=head2 config_dirs

 my $dirs = $xdg->config_dirs;

Returns the system config directories, not modified for the application. Per
the specification, the returned string is :-delimited, except on Windows where it
is C<;>-delimited.

For portability L</config_dirs_list> is preferred.

=head2 config_dirs_list

[version 0.06]

 my @dirs = $xdg->config_dirs_list;

Returns the system config directories as a list of path class objects.

=head2 exe_dir

[version 0.10]

 my $exe = $xdg->exe_dir;

Returns the user-specific executable files directory C<$HOME/.local/bin>, if it exists.  If it
does not exist then C<undef> will be returned.  This directory I<should> be added to the C<PATH>
according to the spec.

=head2 lookup_data_file

 my $xdg = File::XDG->new( name => $name, api => 1 ); # recommended
 my $path = $xdg->lookup_data_File($filename);

Looks up the data file by searching for C<./$name/$filename> (where C<$name> is
provided by the constructor) relative to all base directories indicated by
C<$XDG_DATA_HOME> and C<$XDG_DATA_DIRS>. If an environment variable is either
not set or empty, its default value as defined by the specification is used
instead. Returns a path class object.

 my $xdg = File::XDG->new( name => $name ); # back compat only
 my $path = $xdg->lookup_data_file($subdir, $filename);

Looks up the data file by searching for C<./$subdir/$filename> relative to all base
directories indicated by C<$XDG_DATA_HOME> and C<$XDG_DATA_DIRS>. If an environment
variable is either not set or empty, its default value as defined by the
specification is used instead. Returns a path class object.

=head2 lookup_config_file

 my $xdg = File::XDG->new( name => $name, api => 1 ); # recommended
 my $path = $xdg->lookup_config_file($filename);

Looks up the configuration file by searching for C<./$name/$filename> (where C<$name> is
provided by the constructor) relative to all base directories indicated by
C<$XDG_CONFIG_HOME> and C<$XDG_CONFIG_DIRS>. If an environment variable is
either not set or empty, its default value as defined by the specification
is used instead. Returns a path class object.

 my $xdg = File::XDG->new( name => $name ); # back compat only
 my $path = $xdg->lookup_config_file($subdir, $filename);

Looks up the configuration file by searching for C<./$subdir/$filename> relative to
all base directories indicated by C<$XDG_CONFIG_HOME> and C<$XDG_CONFIG_DIRS>. If an
environment variable is either not set or empty, its default value as defined
by the specification is used instead. Returns a path class object.

=head1 SEE ALSO

L<XDG Base Directory specification, version 0.7|http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html>

=head1 CAVEATS

This module intentionally and out of necessity does not follow the spec on the following platforms:

=over 4

=item C<MSWin32> (Strawberry Perl, Visual C++ Perl, etc)

The spec requires C<:> as the path separator, but use of this character is essential for absolute path names in
Windows, so the Windows Path separator C<;> is used instead.

There are no global data or config directories in windows so the data and config directories are empty list instead of
the default UNIX locations.

The base directory instead of being the user's home directory is C<%LOCALAPPDATA%>.  Arguably the data and config
base directory should be C<%APPDATA%>, but cache should definitely be in C<%LOCALAPPDATA%>, and we chose to use just one
base directory for simplicity.

=back

=head1 SEE ALSO

=over 4

=item L<Path::Class>

Portable native path class used by this module used by default (api = 0) and optionally (api = 1).

=item L<Path::Tiny>

Smaller lighter weight path class used optionally (api = 0) and by default (api = 1).

=item L<Path::Spec>

Core Perl library for working with file and directory paths.

=item L<File::BaseDir>

Provides similar functionality to this module with a different interface.

=back

=head1 AUTHOR

Original author: Síle Ekaterin Aman

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Síle Ekaterin Aman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
