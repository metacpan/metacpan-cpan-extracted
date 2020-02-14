use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Get page files from METS specification.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'METS-Files';
readme_from 'Files.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Error::Pure' => 0.16;
requires 'METS::Parse::Simple' => 0.01;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=METS-Files';
resources 'homepage' => 'https://github.com/michal-josef-spacek/METS-Files';
resources 'repository' => 'git://github.com/michal-josef-spacek/METS-Files';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
