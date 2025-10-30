use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'MARC validator plugins.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'MARC-Validator';
perl_version 5.006002;
readme_from 'Validator.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Business::ISBN' => 0;
requires 'DateTime' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'MARC::Field008' => 0;
requires 'MARC::Leader' => 0.04;
requires 'Mo::utils' => 0.06;
requires 'Mo::utils::Hash' => 0;
requires 'Module::Pluggable' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/MARC-Validator/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/MARC-Validator';
resources 'repository' => 'git://github.com/michal-josef-spacek/MARC-Validator';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'MARC::File::XML' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
