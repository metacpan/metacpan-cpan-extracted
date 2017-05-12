#!perl
use strict;
use ExtUtils::MakeMaker;
use 5.8.1;

WriteMakefile
  (
   AUTHOR => '"Joshua ben Jore" <jjore@cpan.org>',
   SIGN => 1,
   
   NAME => 'Devel::Pointer::PP',
   ABSTRACT_FROM => 'lib/Devel/Pointer/PP.pm',
   VERSION_FROM => 'lib/Devel/Pointer/PP.pm',
   PREREQ_PM => {
		 B => 1.01
		},
  );
