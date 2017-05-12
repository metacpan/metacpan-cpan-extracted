# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Perl module for structured errors with Term::ANSIColor output.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure-ANSIColor';
readme_from 'ANSIColor.pm';
recursive_author_tests('xt');
requires 'Error::Pure::Output::ANSIColor' => 0.01;
requires 'Error::Pure::Utils' => 0.24;
requires 'Exporter' => 0;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Error-Pure-ANSIColor';
resources 'homepage' => 'https://github.com/tupinek/Error-Pure-ANSIColor';
resources 'repository' => 'git://github.com/tupinek/Error-Pure-ANSIColor';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
