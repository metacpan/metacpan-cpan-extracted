use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Common rules for searching DWG files.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'File-Find-Rule-DWG';
readme_from 'DWG.pm';
recursive_author_tests('xt');
requires 'CAD::AutoCAD::Detect' => 0.02;
requires 'File::Find::Rule' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/File-Find-Rule-DWG/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/File-Find-Rule-DWG';
resources 'repository' => 'git://github.com/michal-josef-spacek/File-Find-Rule-DWG';
test_requires 'File::Object' => 0.08;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
