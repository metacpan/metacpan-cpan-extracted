#!/usr/bin/perl

use inc::Module::Install;

name	    'Filter-Simple-Compile';
license     'MIT';
all_from    'lib/Filter/Simple/Compile.pm';
requires    'Module::Compile';

sign; WriteAll;
