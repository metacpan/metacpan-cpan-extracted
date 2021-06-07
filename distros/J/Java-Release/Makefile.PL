use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Parse Java release archives.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Java-Release';
perl_version 5.0100;
requires 'Error::Pure' => 0;
requires 'List::MoreUtils' => 0;
requires 'Mo' => 0;
requires 'Readonly' => 0;
readme_from 'Release.pm';
recursive_author_tests('xt');
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Java-Release/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Java-Release';
resources 'repository' => 'git://github.com/michal-josef-spacek/Java-Release';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
