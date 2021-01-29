use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl Class for getting DICOM DCMTK dcmdump output for DICOM file.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Dicom-DCMTK-DCMDump-Get';
readme_from 'Get.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Dicom-DCMTK-DCMDump-Get/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Dicom-DCMTK-DCMDump-Get';
resources 'repository' => 'git://github.com/michal-josef-spacek/Dicom-DCMTK-DCMDump-Get';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
