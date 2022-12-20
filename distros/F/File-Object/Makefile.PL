use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Object system for filesystem paths.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'File-Object';
readme_from 'Object.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.14;
requires 'Error::Pure' => 0.30;
requires 'File::Spec::Functions' => 0;
requires 'FindBin' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/File-Object/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/File-Object';
resources 'repository' => 'git://github.com/michal-josef-spacek/File-Object';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.16;
test_requires 'File::Spec::Functions' => 0;
test_requires 'FindBin' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.17';

# Run.
WriteAll();
