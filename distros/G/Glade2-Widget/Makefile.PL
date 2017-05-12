#!/usr/bin/perl

use ExtUtils::MakeMaker;

sub MY::postamble {
   package MY;
   "\npredist: all\n" .
   "\t\$(MAKE) manifest\n" .
   "\t\$(MAKE) tardist\n"
}

WriteMakefile(
   MAKEFILE => 'Makefile',
   VERSION_FROM => 'lib/Glade2//Widget.pm',
   NAME => 'Glade2::Widget',
   PREREQ_PM => {
      'POE::Session::GladeXML2' => 0,
   },
   dist => {
      COMPRESS     =>'gzip',
      SUFFIX       =>'gz',
      DIST_DEFAULT => 'predist',
   },
);
