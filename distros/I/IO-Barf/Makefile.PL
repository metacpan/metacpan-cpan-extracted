use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Barfing content to output file.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'IO-Barf';
readme_from 'Barf.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.11;
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'Scalar::Util' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/IO-Barf/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/IO-Barf';
resources 'repository' => 'git://github.com/michal-josef-spacek/IO-Barf';
test_requires 'Digest' => 0;
test_requires 'Digest::SHA' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure' => 0.11;
test_requires 'File::Object' => 0.05;
test_requires 'File::Slurp' => 0;
test_requires 'File::Temp' => 0;
test_requires 'IO::File' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.10';

# Run.
WriteAll();
