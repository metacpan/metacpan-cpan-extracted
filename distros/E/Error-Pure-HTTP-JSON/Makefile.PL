use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl module for HTTP JSON output for structured errors.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure-HTTP-JSON';
readme_from 'JSON.pm';
recursive_author_tests('xt');
requires 'Error::Pure::Utils' => 0.11;
requires 'Error::Pure::Output::JSON' => 0.01;
requires 'Exporter' => 0;
requires 'List::Util' => 1.33;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Error-Pure-HTTP-JSON/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Error-Pure-HTTP-JSON';
resources 'repository' => 'git://github.com/michal-josef-spacek/Error-Pure-HTTP-JSON';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
