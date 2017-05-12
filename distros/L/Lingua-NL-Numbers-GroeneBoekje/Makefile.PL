# Makefile.PL -- Makefile for inwords
# Author          : Johan Vromans
# Created On      : Sat Jun  6 16:08:33 1998
# Last Modified By: Johan Vromans
# Last Modified On: Thu Dec 21 14:23:33 2006
# Update Count    : 27
# Status          : Released

use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME         => "Lingua::NL::Numbers::GroeneBoekje",
   VERSION_FROM => "lib/Lingua/NL/Numbers/GroeneBoekje.pm",
   ($] >= 5.005) ?
   ( AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
     ABSTRACT	=> 'Convert numbers into Dutch words' ) : (),
   EXE_FILES    => [ map { "script/$_" } @scripts ],
 );
