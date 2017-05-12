package Filesys::CygwinPaths;

# This is EXPERIMENTAL, alpha-type code. It is not yet promised that the API
# will remain as is. Please send bug reports and feature requests (of a
# modest nature, please) to the address in the POD below.

use 5.006;
use strict;
use warnings;

BEGIN {
  use Carp qw{verbose};
  if( not $^O =~/cygwin/i ) {
	Carp::croak "You are trying to use this module with a Perl that appears to not ".
	     "be Cygwin perl. This is most inadvisable. -- ";
  }
}

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# This allows declaration	use Filesys::CygwinPaths ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( vetted_path
     fullposixpath posixpath fullwin32path win32path )
  ]  );

our @EXPORT = ( qw{ $PATHSMODE PATHS_mode vetted_path } );
our @EXPORT_OK = ( qw{fullposixpath posixpath fullwin32path win32path},
                   '$PATHSMODE');
use vars qw( $VERSION $PATHSMODE );

=head1 NAME

Filesys::CygwinPaths - Perl extension to get various conversions of path specifications
in the Cygwin port of Perl.

=head2 VERSION 0.04

=cut

$VERSION = '0.04' ;


bootstrap Filesys::CygwinPaths $VERSION;

=head1 SYNOPSIS

    use Filesys::CygwinPaths;
    PATHS_mode('cyg_win32');
	my $HOME = $ENV{'HOME'};

    my @pics_to_ogle = glob("$HOME/mypics/*.jpg");
	foreach my $pic (@pics_to_ogle) {
	   system('C:/Applications/IrfanView/iview32',
	        vetted_path($pic), '/bf /pos=(0,0) /one', "/title=$pic")
         or die "No fun today!";
    }
	system('C:/Applications/IrfanView/iview32', '/killmesoftly');

   OR

    use Filesys::CygwinPaths ':all';
	my $windows_groks_this = fullwin32path("$ENV{HOME}");
	my $posix_style = fullposixpath($ENV{'USERPROFILE'});

	if(posixpath($windows_groks_this) ne $posix_style)
	{
	   print "You don't keep your bash HOME in your NT Profile dir, huh?\n";
    }

=cut



sub PATHS_mode {
  my $selfobj ; # OO-ready
  if(ref $_[0]) {
	$selfobj = shift;
  }
  if(not $_[0] and not defined $PATHSMODE) {
	$PATHSMODE = 'cyg_mixed';
  } elsif(defined $_[0]) {
	  my $arg = shift;
	  $arg eq 'cyg_mixed'?
		 do{ $PATHSMODE = $arg; }
	: $arg eq 'cyg_posix'?
	     do{ $PATHSMODE = $arg; }
	: $arg eq 'cyg_win32'?
	     do{ $PATHSMODE = $arg; }
	:
      do{ Carp::croak "Invalid PATHSMODE name: \"$arg\" -- "; }
	; # end psuedo case / switch statement.
  }
  $selfobj->{'PATHSMODE'} = $PATHSMODE if defined($selfobj); 
  return $PATHSMODE;
}


sub _handle_tilde {

  my $arg = shift;
  return $arg unless $arg =~/^~/;
  my $pathsep = (defined($PATHSMODE) && $PATHSMODE eq 'cyg_win32')?
          '\\' : '/';
  my @homey = split( /\/|$pathsep/, $arg, 2 );
  Carp::croak "Cannot understand your arg: $_[0] -- " unless
     $homey[0] =~/^~\w*\z/;
  # pattern ' m/^~(\w+)?/ ' is tilde with optional username
	 $homey[0] =~ s%^~(\w*)%$1 ?
		   ((getpwnam($1))[7] || "~$1")
		:   (getpwuid($>))[7]
		      %ex;
  return join( $pathsep, $homey[0],$homey[1] );
}

sub vetted_path {
  my $returnpath;
  my $inpath = _handle_tilde(shift);
  if(not defined $PATHSMODE) {
	Carp::carp 'You ought to set $PATHSMODE'.
	 ' before calling this subroutine!'.
	 "\nDefaulting to 'cyg_mixed' style. -- ";
	$PATHSMODE = &PATHS_mode('cyg_mixed');
  }

  $returnpath =
   $PATHSMODE eq 'cyg_mixed'?
      do{ $returnpath = win32path($inpath);
	      $returnpath =~s@\\@/@g; $returnpath; }
  :$PATHSMODE eq 'cyg_posix'?
      posixpath($inpath)
  :$PATHSMODE eq 'cyg_win32'?
      win32path($inpath)
  : '' # should never happen.
  ; # end psuedo case / switch statement

   $returnpath;
}


#-----------------------------------------------------------------#
#                                                                 #
#       CALL THE ACTUAL XS INTERFACE C FUNCTIONS                  #
#                                                                 #
#-----------------------------------------------------------------#


sub fullposixpath {
  my ($input, $retval, $output);
  $input = _handle_tilde(shift);
  if( $input eq '') {
	Carp::carp "No path argument supplied! -- ";
	return '';
  }
  $output = cygwin_conv_to_full_posix_path($input);
}


sub fullwin32path {
  my ($input, $retval, $output);
  $input = _handle_tilde(shift);
  if( $input eq '') {
	Carp::carp "No path argument supplied! -- ";
	return '';
  }
  $output = ucfirst
     cygwin_conv_to_full_win32_path($input);
}


sub posixpath {
  my ($input, $retval, $output);
  $input = _handle_tilde(shift);
  if( $input eq '') {
	Carp::carp "No path argument supplied! -- ";
	return '';
  }
  $output = cygwin_conv_to_posix_path($input);
}


sub win32path {
  my ($input, $retval, $output);
  $input = _handle_tilde(shift);
  if( $input eq '') {
	Carp::carp "No path argument supplied! -- ";
	return '';
  }
  $output = cygwin_conv_to_win32_path($input);
}

1;
__END__

=head1 DESCRIPTION

B<Filesys::CygwinPaths> is a B<Cygwin-specific> module created to ease the
author's occasional pique over the little quirks that come up with using
Perl on Cygwin, the free POSIX emulation psuedoplatform for Microsoft
Windows(tm). The subroutines it exports allow various kinds of path
conversions to be made in a fairly concise, simple, procedural manner. At
the present time the module does not have an OO interface but one might be
added in the future. The module can be used according to two diffent
approaches, which are outlined below.

Note: Hopefully it is obvious that the module can be neither built nor used
on any platform besides Perl for Cygwin, and there would be no reason to
want to do so.

=head2 Usage Styles

Two slightly different ways of using B<Filesys::CygwinPaths> are available. The
first, and recommended, way is to tell Perl once and for all (for the
duration of your script) what I<mode> you need to use in conversing
with, say external non-Cygwin applications. To do this, say something like:

	use Filesys::CygwinPaths;
	 PATHS_mode( 'cyg_mixed' );
	 my $own_name = vetted_path($0);
	 print "I am $own_name, how are you today?\n";

And that will set the I<mode> to C<cyg_mixed> for the duration of the script
or until you change it to something else.

The 3 recognized settings for C<$PATHSMODE> are:

S<       C<cyg_mixed> (like: F<C:/foobar/sugarplum/fairy.txt>) >
S<       C<cyg_win32> (like: F<C:\foobar\sugarplum\fairy.txt>) >
S<       C<cyg_posix> (like: F</cygdrive/c/sugarplum/fairy.txt>) >

Alternatively you might prefer the more specific and elaborate full set of
subroutines to be made available to you by name (C<:all>). These can be
called to get the specific translation mode you desire. Listed below.
However, at present, using C<vetted_path> is the only means by which to get
"mixed" mode paths.

=over 4

=item vetted_path($path_in)

make any translations necessary to transform the path argument according to the setting of the global (B<Filesysy::CygwinPaths>) variable C<$PATHSMODE>. If this variable is not already set when C<vetted_path()> is called, it will set to the default of C<cyg_mixed> and complain a little at you. Set the script-wide mode you desire for C<vetted_path()> to use by

=over 3

=item (a) setting PATHSMODE directly in your script

   $PATHSMODE = 'cyg_posix';  # not "my" (!!)

=item (b) calling the subroutine C<PATHS_mode> with the desired value. See below.

=back

This function provides the "mixed mode" paths that aren't directly provided
by any functions in the Cygwin API. That is its main raison d'tre.

=item PATHS_mode(<mode>)

set or query the current I<mode> under which C<vetted_path> will
return a path spec.


=item posixpath($path_in)

return the POSIX-style path spec (filename) for the given argument. If the
argument is a relative path, returns a relative path.


=item win32path($path_in)

return the Win32 (Microsoft Windows standard) style path spec for the given
argument. If the argument is a relative path, returns a relative path.


=item fullposixpath($path_in)

return the fully-qualified (absolute) path spec (filename) for the given
argument, in POSIX-style.


=item fullwin32path($path_in)

return the fully-qualified path spec in Windows style.

=back

=head2 Changes

 >= 0.04 -- see CHANGES file in distrubution archive.

  0.03 Added private subroutine to provide the HOME directory if the
       arg began with "~<something>". Added ucfirst() call to
       fullwin32path(), to force uniformity of results (all drive
       letters UpperCase). Changed all instances of using the term
       "protocol" in subs and variables to "mode".  ;-)

  0.02 First upload to CPAN (unregistered).

  0.01 First build.

=head2 Notes on the XS programming (C interface)

TODO.

=over 3

=item *

Another way to do the call to the xs interface would have been, maybe:

 sub conv_to_win32_path {
   my $in= shift(@_);
   my $out= "\0" x PATH_MAX();
   cygwin_conv_to_win 32_path($in,$out);
   return $out;
 }

=back

=head1 BUGS

We shall see.

The return values (int C type) of the Cygwin functions are being discarded.
The author confesses his crime. This may change in a future update, but for
now, is how it is.


=head1 SEE ALSO

L<File::Spec>, L<File::Spec::Unix>, L<File::Basename>, L<File::PathConvert>,
L<Env>.

=head1 CREDITS

Tye McQueen for his XSeedingly generous help with the C interface work for
this module. ;-)

Kazuko Andersen for her patience and for bringing food so I could finish
working on this module ;-).

=head1 AUTHOR

Soren (Michael) Andersen (CPAN id SOMIAN), <somian@pobox.com>.


=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2002 by Soren Andersen.
This program is free software; you can redistribute it and/or
modify it under the terms of the Perl Artistic License or the
GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

If you do not have a copy of the GNU General Public License write to
the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
MA 02139, USA.


=cut

