use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Output bioperl subroutines for Error::Pure.';
author 'Michal Spacek <skim@cpan.org>';
license 'bsd';
name 'Error-Pure-Output-Bio';
readme_from 'Bio.pm';
requires 'Error::Pure::Utils' => 0.11;
requires 'Exporter' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Error-Pure-Output-Bio/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Error-Pure-Output-Bio';
resources 'repository' => 'git://github.com/michal-josef-spacek/Error-Pure-Output-Bio';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
