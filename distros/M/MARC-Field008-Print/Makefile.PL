use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'MARC field 008 class for print.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'MARC-Field008-Print';
perl_version 5.006002;
readme_from 'Print.pm';
recursive_author_tests('xt');
requires 'Check::Term::Color' => 0;
requires 'Class::Utils' => 0.03;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'MARC::Field008::L10N' => 0;
requires 'Mo::utils' => 0.06;
requires 'Mo::utils::Language' => 0.05;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/MARC-Field008-Print/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/MARC-Field008-Print';
resources 'repository' => 'git://github.com/michal-josef-spacek/MARC-Field008-Print';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
