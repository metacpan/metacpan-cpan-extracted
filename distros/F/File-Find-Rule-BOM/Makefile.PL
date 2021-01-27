use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Common rules for searching for BOM in files.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'File-Find-Rule-BOM';
readme_from 'BOM.pm';
recursive_author_tests('xt');
requires 'String::BOM' => 0;
requires 'File::Find::Rule' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/File-Find-Rule-BOM/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/File-Find-Rule-BOM';
resources 'repository' => 'git://github.com/michal-josef-spacek/File-Find-Rule-BOM';
test_requires 'File::Object' => 0.08;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
