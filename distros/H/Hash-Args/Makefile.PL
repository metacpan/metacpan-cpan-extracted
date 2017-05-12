#!/usr/bin/env perl

use inc::Module::Install;

name     'Hash-Args';
license  'MIT';
all_from 'lib/Hash/Args.pm';

requires 'parent';
requires 'Carp';
requires 'Exporter';
requires 'Scalar::Util';

test_requires 'Test::More';

auto_install;
WriteAll;
