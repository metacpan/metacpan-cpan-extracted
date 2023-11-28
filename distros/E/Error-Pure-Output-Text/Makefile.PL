use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Output text subroutines for Error::Pure.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'Cwd' => 0;
author_requires 'English' => 0;
author_requires 'File::Spec::Functions' => 0;
author_requires 'FindBin' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure-Output-Text';
readme_from 'Text.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Error-Pure-Output-Text/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Error-Pure-Output-Text';
resources 'repository' => 'git://github.com/michal-josef-spacek/Error-Pure-Output-Text';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.24';

# Run.
WriteAll();
