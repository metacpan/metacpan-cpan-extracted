use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl module for structured errors.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'Cwd' => 0;
author_requires 'English' => 0;
author_requires 'File::Spec::Functions' => 0;
author_requires 'FindBin' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure';
perl_version 5.008;
readme_from 'Pure.pm';
recursive_author_tests('xt');
requires 'Cwd' => 0;
requires 'English' => 0;
requires 'Exporter' => 0;
requires 'Error::Pure::Output::Text' => 0.21;
requires 'List::Util' => 1.33;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Error-Pure/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Error-Pure';
resources 'repository' => 'git://github.com/michal-josef-spacek/Error-Pure';
test_requires 'Capture::Tiny' => 0;
test_requires 'Cwd' => 0;
test_requires 'English' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'FindBin' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.33';

# Run.
WriteAll();
