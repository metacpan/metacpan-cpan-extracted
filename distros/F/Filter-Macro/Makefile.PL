#!/usr/local/bin/perl

use inc::Module::Install;

name        'Filter-Macro';
license	    'MIT';
all_from    'lib/Filter/Macro.pm';
requires    'Filter::Simple::Compile';

sign; WriteAll;
