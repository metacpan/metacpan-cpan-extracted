# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Perl module for structured errors.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure';
readme_from 'Pure.pm';
recursive_author_tests('xt');
requires 'Cwd' => 0;
requires 'English' => 0;
requires 'Exporter' => 0;
requires 'Error::Pure::Output::Text' => 0.21;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Error-Pure';
resources 'homepage' => 'https://github.com/tupinek/Error-Pure';
resources 'repository' => 'git://github.com/tupinek/Error-Pure';
test_requires 'Cwd' => 0;
test_requires 'English' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'FindBin' => 0;
test_requires 'IO::CaptureOutput' => 1.02;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.24';

# Run.
WriteAll();
