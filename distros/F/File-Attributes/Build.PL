#!/usr/bin/perl
# Makefile.PL 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use inc::Module::Install;

name('File-Attributes');
author('Jonathan Rockway <jrockway@cpan.org>');
version_from('lib/File/Attributes.pm');
abstract_from('lib/File/Attributes.pm');
license('Perl');
include('ExtUtils::AutoInstall');

requires('Exporter');
requires('Module::Pluggable');
requires('Carp');
requires('Best' => 0.06);
requires('YAML');
requires('File::Spec');

build_requires('Directory::Scratch' => 0.05);
build_requires('Test::More');

features('YAML::Syck for better performance'
	 => ['YAML::Syck' => 0]);

auto_install();
WriteAll();
