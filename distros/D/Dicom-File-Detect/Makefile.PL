use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Detect DICOM file through magic string.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Dicom-File-Detect';
requires 'Readonly' => 0;
requires 'perl' => '5.8.0';
readme_from 'Detect.pm';
recursive_author_tests('xt');
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Dicom-File-Detect/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Dicom-File-Detect';
resources 'repository' => 'git://github.com/michal-josef-spacek/Dicom-File-Detect';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'File::Object' => 0.05;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
