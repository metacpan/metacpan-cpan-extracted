use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'MARC leader class for print.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'MARC-Leader-Print';
perl_version 5.006002;
readme_from 'Print.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Data::MARC::Leader::Utils' => 0.03;
requires 'English' => 0;
requires 'Error::Pure' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/MARC-Leader-Print/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/MARC-Leader-Print';
resources 'repository' => 'git://github.com/michal-josef-spacek/MARC-Leader-Print';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
