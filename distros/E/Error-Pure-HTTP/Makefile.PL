use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl module for plain HTTP output for structured errors.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure-HTTP';
readme_from 'HTTP.pm';
recursive_author_tests('xt');
requires 'Error::Pure::Utils' => 0.09;
requires 'Error::Pure::Output::Text' => 0.09;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Error-Pure-HTTP/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Error-Pure-HTTP';
resources 'repository' => 'git://github.com/michal-josef-spacek/Error-Pure-HTTP';
test_requires 'English' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.16';

# Run.
WriteAll();
