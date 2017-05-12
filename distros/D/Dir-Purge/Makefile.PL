#!/usr/bin/perl -w

use ExtUtils::MakeMaker;
use strict;

WriteMakefile
  (
   NAME	   => 'Dir::Purge',
   VERSION_FROM => 'lib/Dir/Purge.pm',
   ($] >= 5.005) ?
   ( AUTHOR    => "Johan Vromans <jvromans\@squirrel.nl>",
     ABSTRACT  => "Selective purging of directories and files." ) : (),
   PREREQ_PM => { 'Test::More' => 0 },
);
