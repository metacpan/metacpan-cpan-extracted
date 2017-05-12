#!perl -w
# Makefile.pl for Inline::Octave
# $Id: Makefile.PL,v 1.9 2005/03/07 22:33:58 aadler Exp $

use strict;
use ExtUtils::MakeMaker;

#
#   Find the octave interpreter
#

my $octave= "octave";
my $octave_validated= 0;

# check if interpreter was specified on cmd line
foreach (@ARGV) {
   if (/^OCTAVE=(.+)/) {
      $octave= $1;
      $octave_validated= 1;
      $_= "";
   }
}   

while (not $octave_validated) {
   $octave_validated= 1 if `$octave -v` =~ /Octave, version ([2-9]\.\d+\.(\d+|cvs))/;
   my $octave_version= $1;

   if ($octave_validated) {
      print "Found GNU Octave interpreter:[$octave] (version $octave_version)\n";
      print "Enter new executable path or <RETURN> to accept: ";
   } else {
      print "Unable to find GNU Octave interpreter at:[$octave]\n";
      print "Please enter new path to executable: " ;

   }
   
   chomp( my $inp= <STDIN> );
   if ($inp) {
      $octave_validated= 0;
      $octave= $inp;
   }
}

#
# Rewrite Octave.pm 
#
   print "\nFixing Octave.pm for octave path...\n" ;
   open(OCTAVE, "<Octave.pm") or die "Can't open Octave.pm for reading" ;
   my @lines = <OCTAVE> ;
   close(OCTAVE) ;

   open(OCTAVE, ">Octave.pm") or die "Can't open Octave.pm for writing" ;
   foreach my $line (@lines) {
      $line =~ 
         s{(\$octave_interpreter_bin\s*=\s*)'.+?'(\s*#\s*_EDITLINE_MARKER_)}
          {$1\'$octave\'$2};
      print OCTAVE $line ;
   }
   close(OCTAVE) ;


WriteMakefile(
    'NAME'         => 'Inline::Octave',
    'VERSION_FROM' => 'Octave.pm',
    'PREREQ_PM'    => { 'Inline'   => 0.43,
#                       'IPC::Run' => 0.78
                      },
    'clean'        => {FILES => '_Inline/'},  
);
