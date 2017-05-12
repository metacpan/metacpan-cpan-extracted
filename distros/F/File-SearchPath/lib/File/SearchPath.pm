package File::SearchPath;

=head1 NAME

File::SearchPath - Search for a file in an environment variable path

=head1 SYNOPSIS

  use File::SearchPath qw/ searchpath /;

  $file = searchpath( 'libperl.a', env => 'LD_LIBRARY_PATH' );
  $file = searchpath( 'my.cfg', env => 'CFG_DIR', subdir => 'ME' );

  $path = searchpath( $file, env => 'PATH', exe => 1 );
  $path = searchpath( $file, env => 'PATH', dir => 1 );

  $file = searchpath( 'ls', $ENV{PATH} );

  $exe = searchpath( 'ls' );

=head1 DESCRIPTION

This module provides the ability to search a path-like environment
variable for a file (that does not necessarily have to be an
executable).

=cut

use 5.006;
use Carp;
use warnings;
use strict;

use base qw/ Exporter /;
use vars qw/ $VERSION @EXPORT_OK /;

use File::Spec;
use Config;

$VERSION = '0.07';

@EXPORT_OK = qw( searchpath );

=head1 FUNCTIONS

The following functions can be exported by this module.

=over 4

=item B<searchpath>

This is the core function. The only mandatory argument is the name of
a file to be located. The filename should not be absolute although it
can include directory specifications.

  $path = searchpath( $file );
  @matches = searchpath( $file );

If only two arguments are provided, it is assumed that the second
argument is a path-like string. This interface is provided for
backwards compatibility with C<File::SearchPath> version 0.01. It is not
as portable as specifying the name of the environment variable. Note also
that no specific attempt will be made to check whether the file is
executable when the subroutine is called in this way.

  $path = searchpath( $file, $ENV{PATH} );

By default, this will search in $PATH for executable files and is
equivalent to:

  $path = searchpath( $file, env => 'PATH', exe => 0 );

Hash-like options can be used to alter the behaviour of the
search:

=over 8

=item env

Name of the environment variable to use as a starting point for the
search. Should be a path-like environment variable such as $PATH,
$LD_LIBRARY_PATH etc. Defaults to $PATH. An error occurs if the
environment variable is not set or not defined. If it is defined but
contains a blank string, the current directory will be assumed.

=item exe

If true, only executable files will be located in the search path.
If $PATH is being searched, the default is for this to be true. For all
other environment variables the default is false. If "dir" option
is specified "exe" will always default to false.

=item dir

If true, only directories will be located in the search path. Default
is false. "dir" and "exe" are not allowed to be true in the same
call. (triggering a croak() on error).

=item subdir

If you know that your file is in a subdirectory of the path described
by the environment variable, this direcotry can be specified here.
Alternatively, the path can be included in the file name itself.

=back

In scalar context the first match is returned. In list context all
matches are returned in the order corresponding to the directories
listed in the environment variable.

Returns undef (or empty list) if no match could be found.

If an absolute file name is provided, that filename is returned if it
exists and is readable, else undef is returned.

=cut

sub searchpath {
  my $file = shift;

  # read our arguments and assign defaults. Behaviour depends on whether
  # we have a single argument remaining or not.
  my %options;

  # If we only have one more argument then it must be the contents
  # of a path variable
  my $path_contents;
  if ( scalar(@_) == 1) {
    # Read the contents and store in options hash
    # along with the backwards compatibility behaviour
    %options = ( contents => shift,
		 exe => 0,
		 dir => 0,
		 subdir => File::Spec->curdir,
	       );

  } else {

    # options handling since we have zero or more than one argument.
    # set up the default behaviour
    # The exe() defaulting is env dependent
    my %defaults = ( env => 'PATH', subdir => File::Spec->curdir );

    %options = ( %defaults, @_ );

    # if we specify a dir option then we default to no exe regardless
    # of PATH
    if (!exists $options{exe} && !exists $options{dir}) {
      # exe was not specified
      $options{exe} = ( $options{env} eq 'PATH' ? 1 : 0 );
    }

    croak "Both exe and dir options were set in call to searchpath()"
      if ($options{exe} && $options{dir});

  }

  # check for absolute file name and behave accordingly
  if (File::Spec->file_name_is_absolute( $file )) {
    return (_file_ok($file, $options{exe}, $options{dir}) ? $file : () );
  }

  # if exe is true we can simply use Env::Path directly. It doesn't
  # really simplify any code though since we still have to write 
  # the other search

  # first get the search directories from the path variable
  my @searchdirs = _env_to_dirs( $options{env}, $options{contents} );

  # Now do the looping
  my @matches;

  for my $d (@searchdirs) {
    # blank means current directory
    $d = File::Spec->curdir unless $d;

    # Create the filename
    my $testfile;
    if ($options{dir}) {
      $testfile = File::Spec->catdir( $d, $options{subdir}, $file);
    } else {
      $testfile = File::Spec->catfile( $d, $options{subdir}, $file);
    }

    # does the file exist?
    next unless _file_ok( $testfile, $options{exe}, $options{dir} );

    # File looks to be found store it
    push(@matches, $testfile);

    # if we are in a scalar context we do not need to keep on looking
    last unless wantarray();

  }

  # return the result
  if (wantarray) {
    return @matches;
  } else {
    return $matches[0];
  }
}

=back

=begin __PRIVATE__FUNCTIONS__

=head2 Private Functions

=over 4

=item B<_env_to_dirs>

Given an environment variable, splits it into chunks and returns
the list of directories to be searched.

If Env::Path is installed, it is used since it understands a more
varied set of path delimiters, otherwise the variable is split on
the value of $Config{path_sep}.

  @dirs = _env_to_dirs( 'PATH' );

Also, we can pass in the actual contents as a second argument. In this
case it is only read if the first is undef.

  @dirs = _env_to_dirs( undef, 'dir1:dir2' );

=cut

sub _env_to_dirs {
  my $var = shift;
  my $contents = shift;

  if (!defined $var && !defined $contents) {
    croak "Error extracting directories from environment. No defined values supplied. Internal programming error";
  }

  # behaviour now depends on whether we were given the actual
  # contents or the name of the variable. Variable name trumps contents.

  if (defined $var) {

    croak "Environment variable $var is not defined. Unable to search it\n"
      if !exists $ENV{$var};

    croak "Environment variable does exist but it is not defined. Unable to search it\n"
      unless defined $ENV{$var};
  }
  my $use_env_path;
  {
    # Localise $@ so that we can use this command from perldl shell
    local $@;
    eval { require Env::Path };
    $use_env_path = ( $@ ? 0 : 1 );
  }
  if (!$use_env_path || defined $contents) {
    # no Env::Path so we just split on :
    my $path = (defined $contents? $contents : $ENV{$var});
    my $ps = $Config{path_sep};
    return split(/\Q$ps\E/, $path);
  } else {
    my $path = Env::Path->$var;
    return $path->List;
  }
}

=item B<_file_ok>

Tests the file for existence, fileness and readability.

  $isthere = _file_ok( $file );

Returns true if the file passes.

An optional argument can be used to add a test for exectuableness.

  $isthere_and_exe = _file_ok( $file, 1 );

An additional optional argument can be used to add a test for
directory as opposed to file existence.

  $isthere_and_dir = _file_ok( $dir, 0, 1 );

=cut

sub _file_ok {
  my $testfile = shift;
  my $testexe = shift;
  my $testdir = shift;

  # do not allow both dir and exe flags
  return 0 if ($testexe && $testdir);

  return unless -e $testfile;
  return unless -r $testfile;

  if ($testdir) {
    return (-d $testfile);
  } elsif ($testexe) {
    return (-f $testfile && -x $testfile);
  } else {
    return (-f $testfile);
  }
}


=end __PRIVATE__FUNCTIONS__

=head1 HISTORY

C<File::SearchPath> used to exist on CPAN (now on backpan) and was
written by Robert Spier.  This version is completely new but retains
an interface that is compatible with Robert's version. Thanks to
Robert for allowing me to reuse this module name.

=head1 NOTES

If C<Env::Path> module is installed it will be used. This allows for
more flexibility than simply assuming colon-separated paths.

=head1 SEE ALSO

L<Env::Path>, L<File::Which>, L<File::Find>, L<File::Find::Run>,
L<File::Where>.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

Copyright (C) 2005,2006, 2008 Particle Physics and Astronomy Research Council.
Copyright (C) 2009-2010 Science and Technology Facilities Council.
Copyright (C) 2015 Tim Jenness
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
