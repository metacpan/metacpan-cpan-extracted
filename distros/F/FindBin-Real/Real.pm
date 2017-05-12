# FindBin/Real.pm
#
# Copyright (c) 1995 Graham Barr & Nick Ing-Simmons. All rights reserved.
# Copyright (c) 2003-2005 Serguei Trouchelle. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# History:
#  1.05  2007/02/04 Quality update (Test::Pod, Test::Pod::Coverage)
#  1.04  2005/02/07 Refactured version. About +50% in performance.
#                   Version is corrected to $FindBin::Real::VERSION.
#                   Fixed problem with Dir/RealDir
#                   Some tests added.
#  1.03  2004/02/15 Added BinDepth() function
#                   (Suggested by Tielman de Villiers)
#  1.02  2003/08/10 Fixed bug in Makefile.PM (Findbin -> FindBin)
#                   ^M symbols are removed from sources
#                   (Thanks to Mike Castle)
#  1.01  2003/08/08 Added some tests and README
#  1.00  2003/08/06 Initial revision

=head1 NAME

FindBin::Real - Locate directory of original perl script 

=head1 SYNOPSIS

 use FindBin::Real;
 use lib FindBin::Real::Bin() . '/../lib';

 or

 use FindBin::Real qw(Bin);
 use lib Bin() . '/../lib';

 or

 # Run from /usr/bin/www/some/path/ or /usr/bin/www/some/other/path or any
 use FindBin::Real qw(BinDepth);
 use lib BinDepth(3) . '/lib';
 # And always got /usr/bin/www/lib !

=head1 DESCRIPTION

Locates the full path to the script bin directory to allow the use
of paths relative to the bin directory.

This allows a user to setup a directory tree for some software with
directories E<lt>rootE<gt>/bin and E<lt>rootE<gt>/lib and then the above example will allow
the use of modules in the lib directory without knowing where the software
tree is installed.

If perl is invoked using the B<-e> option or the perl script is read from
C<STDIN> then FindBin sets both C<Bin()> and C<RealBin()> return values to the current
directory.

=head1 EXPORTABLE FUNCTIONS

=head2 Bin

- path to bin directory from where script was invoked

=head2 Script

- basename of script from which perl was invoked

=head2 RealBin

- Bin() with all links resolved

=head2 RealScript

- Script() with all links resolved

=head2 BinDepth(n)

- path to n-level parent directory

=head2 Dir()

- the same as Bin()

=head2 RealDir()

- the same as RealBin()

=head1 KNOWN ISSUES

If there are two modules using C<FindBin::Real> from different directories
under the same interpreter, this WOULD work. Since C<FindBin::Real> uses
functions instead of C<BEGIN> block in C<FindBin>, it'll be executed on every script,
and all callers will get it right. This module can be used under mod_perl and other persistent
Perl environments, where you shouldn't use C<FindBin>.

=head1 KNOWN BUGS

If perl is invoked as

   perl filename

and I<filename> does not have executable rights and a program called I<filename>
exists in the users C<$ENV{PATH}> which satisfies both B<-x> and B<-T> then FindBin
assumes that it was invoked via the C<$ENV{PATH}>.

Workaround is to invoke perl as

 perl ./filename

=head1 AUTHORS

Serguei Trouchelle E<lt>F<stro@railways.dp.ua>E<gt>

FindBin::Real uses code from FindBin module, which was written by

Graham Barr E<lt>F<gbarr@pobox.com>E<gt>
Nick Ing-Simmons E<lt>F<nik@tiuk.ti.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr & Nick Ing-Simmons. All rights reserved.
Copyright (c) 2003-2005 Serguei Trouchelle. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package FindBin::Real;
use Carp;
require 5.006;
require Exporter;
use Cwd qw(getcwd abs_path);
use Config;
use File::Basename;
use File::Spec;

use strict;
use warnings;

our @EXPORT_OK = qw(Bin Script RealBin RealScript Dir RealDir BinDepth);
our %EXPORT_TAGS = (ALL => [qw(Bin Script RealBin RealScript Dir RealDir BinDepth)]);
our @ISA = qw(Exporter);

$FindBin::Real::VERSION = "1.05";

my $keyBin        = 1;
my $keyScript     = 2;
my $keyRealBin    = 3;
my $keyRealScript = 4;

#
# mastermind
#
sub mastermind {
  my $meth = shift || die 'Invalid call to mastermind';

  if ($0 eq '-e' || $0 eq '-') {
    return getcwd() if $meth == $keyBin || $meth == $keyRealBin;
    return $0 if $meth == $keyScript || $meth == $keyRealScript;
  }
  if ($^O eq 'VMS') {
#   ($Bin,$Script) = VMS::Filespec::rmsexpand($0) =~ /(.*\])(.*)/s;
    return VMS::Filespec::rmsexpand($0) =~ /(.*\])/s if $meth == $keyBin || $meth == $keyRealBin;
    return VMS::Filespec::rmsexpand($0) =~ /.*\](.*)/s if $meth == $keyScript || $meth == $keyRealScript;
  }

  my ($Bin, $Script, $RealBin, $RealScript, $Dir, $RealDir);
  my $script = $0;

  my $dosish = ($^O eq 'MSWin32' or $^O eq 'os2');
  unless(($script =~ m#/# || ($dosish && $script =~ m#\\#))
         && -f $script)
   {
    my $dir;
    foreach $dir (File::Spec->path)
     {
     my $scr = File::Spec->catfile($dir, $script);
     if(-r $scr && (!$dosish || -x _))
      {
       $script = $scr;

       if (-f $0)
        {
         # $script has been found via PATH but perl could have
         # been invoked as 'perl file'. Do a dumb check to see
         # if $script is a perl program, if not then $script = $0
         #
         # well we actually only check that it is an ASCII file
         # we know its executable so it is probably a script
         # of some sort.

         $script = $0 unless(-T $script);
        }
       last;
      }
    }
  }

  croak("Cannot find current script '$0'") unless(-f $script);

  # Ensure $script contains the complete path incase we C<chdir>

  $script = File::Spec->catfile(getcwd(), $script)
    unless File::Spec->file_name_is_absolute($script);

  if ($meth == $keyBin or $meth == $keyScript) {
    ($Script,$Bin) = fileparse($script);
  } else {
    # RealBin/RealScript:
    # Resolve $script if it is a link
    while(1) {
      my $linktext = readlink($script);

      ($RealScript,$RealBin) = fileparse($script);
      last unless defined $linktext;

      $script = (File::Spec->file_name_is_absolute($linktext))
                 ? $linktext
                 : File::Spec->catfile($RealBin, $linktext);
    }
  }
  # Get absolute paths to directories
  $Bin     = abs_path($Bin)     if $Bin;
  $RealBin = abs_path($RealBin) if $RealBin;
 
  return $Bin if $meth == $keyBin;
  return $Script if $meth == $keyScript;
  return $RealBin if $meth == $keyRealBin;
  return $RealScript if $meth == $keyRealScript;
}

sub Bin {
  return mastermind($keyBin);
}

sub Script {
  return mastermind($keyScript);
}

sub RealBin {
  return mastermind($keyRealBin);
}

sub RealScript {
  return mastermind($keyRealScript);
}

sub Dir {
  return mastermind($keyBin);
}

sub RealDir {
  return mastermind($keyRealBin);
}

sub BinDepth($) {
  my $depth = shift;
  my $Bin = Bin();
  return $Bin unless $depth =~ /\d+/;
  return $1 . $2   if $Bin =~ m!(.*?)((/[^/]+?){$depth})/!;
  return $Bin;
}

1; # Keep require happy

                    	