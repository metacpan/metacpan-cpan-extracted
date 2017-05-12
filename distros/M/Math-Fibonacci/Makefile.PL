#!/usr/bin/perl -sw
##
## Makefile.PL for Math::Fibonacci
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Makefile.PL,v 1.2 2001/04/28 20:36:55 vipul Exp $

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Math::Fibonacci',
    'AUTHOR'       => 'Vipul Ved Prakash <mail@vipul.net>',
    'VERSION_FROM' => 'lib/Math/Fibonacci.pm',
    'PREREQ_PM'    => { 
                      } 
);

