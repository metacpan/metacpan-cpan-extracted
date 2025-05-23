use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'DICOM UID generator.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Dicom-UID-Generator';
perl_version 5.008;
readme_from 'Generator.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.07;
requires 'DateTime::HiRes' => 0;
requires 'English' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Dicom-UID-Generator/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Dicom-UID-Generator';
resources 'repository' => 'git://github.com/michal-josef-spacek/Dicom-UID-Generator';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
