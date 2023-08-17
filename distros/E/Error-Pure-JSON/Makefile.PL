use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl module for JSON output for structured errors.';
author 'Michal Josef Spacek <skim@cpan.org>';
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
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Error-Pure-JSON/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Error-Pure-JSON';
resources 'repository' => 'git://github.com/michal-josef-spacek/Error-Pure-JSON';
test_requires 'Capture::Tiny' => 0;
test_requires 'Cwd' => 0;
test_requires 'English' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'FindBin' => 0;
test_requires 'JSON' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
