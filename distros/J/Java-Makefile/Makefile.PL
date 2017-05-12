#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;
require 5.006;
my @basics = ( AUTHOR       => 'David Helkowski <cpan@codechild.com>',
               ABSTRACT     => 'Script to generate Makefile for building Java projects into a single standalone jar',
               NAME         => 'Java::Makefile',
               VERSION_FROM => 'lib/Java/Makefile.pm',
               PREREQ_PM    => {
                    "XML::Bare" => "0.53"
               }
             );
if( $ExtUtils::MakeMaker::VERSION >= 6.31 ) {
  push( @basics, LICENSE => 'perl' );
}

WriteMakefile( @basics );