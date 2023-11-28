use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl class for reading/writing DCMTK dcmqrscp configuration file.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Dicom-DCMTK-DCMQRSCP-Config';
readme_from 'Config.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Error::Pure' => 0.16;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/'.
	'Dicom-DCMTK-DCMQRSCP-Config/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/'.
	'Dicom-DCMTK-DCMQRSCP-Config';
resources 'repository' => 'git://github.com/michal-josef-spacek/'.
	'Dicom-DCMTK-DCMQRSCP-Config';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.16,
test_requires 'File::Object' => 0.08;
test_requires 'Perl6::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
