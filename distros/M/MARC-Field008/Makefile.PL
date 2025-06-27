use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'MARC class for 008 field.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'MARC-Field008';
perl_version 5.006002;
readme_from 'Field008.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Data::MARC::Field008' => 0;
requires 'Data::MARC::Field008::Book' => 0.03;
requires 'Data::MARC::Field008::ComputerFile' => 0.03;
requires 'Data::MARC::Field008::ContinuingResource' => 0.03;
requires 'Data::MARC::Field008::Map' => 0.03;
requires 'Data::MARC::Field008::MixedMaterial' => 0.03;
requires 'Data::MARC::Field008::Music' => 0.03;
requires 'Data::MARC::Field008::VisualMaterial' => 0.03;
requires 'Error::Pure' => 0;
requires 'List::Util' => 1.33;
requires 'Mo::utils' => 0.08;
requires 'Scalar::Util' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/MARC-Field008/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/MARC-Field008';
resources 'repository' => 'git://github.com/michal-josef-spacek/MARC-Field008';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'MARC::Leader' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
