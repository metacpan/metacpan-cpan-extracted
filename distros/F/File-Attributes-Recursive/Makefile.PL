#!/usr/bin/perl
# Makefile.PL 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use inc::Module::Install;

name('File-Attributes-Recursive');
author('Jonathan Rockway <jrockway@cpan.org');
version_from('lib/File/Attributes/Recursive.pm');
abstract_from('lib/File/Attributes/Recursive.pm');
license('Perl');
include('ExtUtils::AutoInstall');

requires('Path::Class');
requires('Exporter');
requires('File::Attributes');
requires('Cwd');

build_requires('Test::More');
build_requires('Directory::Scratch');

auto_install();
WriteAll();
