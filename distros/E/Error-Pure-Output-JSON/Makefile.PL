# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Output JSON subroutines for Error::Pure.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure-Output-JSON';
readme_from 'lib/Error/Pure/Output/JSON.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'JSON' => '2.50';
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Error-Pure-Output-JSON';
resources 'homepage' => 'https://github.com/tupinek/Error-Pure-Output-JSON';
resources 'repository' => 'git://github.com/tupinek/Error-Pure-Output-JSON';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.10';

# Run.
WriteAll();
