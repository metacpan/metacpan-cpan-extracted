# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Perl module for JSON output for structured errors.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure-JSON';
readme_from 'JSON.pm';
recursive_author_tests('xt');
requires 'Error::Pure::Utils' => 0.18;
requires 'Error::Pure::Output::JSON' => 0.09;
requires 'Exporter' => 0;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Error-Pure-JSON';
resources 'homepage' => 'https://github.com/tupinek/Error-Pure-JSON';
resources 'repository' => 'git://github.com/tupinek/Error-Pure-JSON';
test_requires 'Cwd' => 0;
test_requires 'English' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'FindBin' => 0;
test_requires 'IO::CaptureOutput' => 1.02;
test_requires 'JSON' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
