use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl module for structured errors with Term::ANSIColor output.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure-ANSIColor';
readme_from 'ANSIColor.pm';
recursive_author_tests('xt');
requires 'Error::Pure::Output::ANSIColor' => 0.04;
requires 'Error::Pure::Utils' => 0.24;
requires 'Exporter' => 0;
requires 'List::Util' => 1.33;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Error-Pure-ANSIColor/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Error-Pure-ANSIColor';
resources 'repository' => 'git://github.com/michal-josef-spacek/Error-Pure-ANSIColor';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.29';

# Run.
WriteAll();
