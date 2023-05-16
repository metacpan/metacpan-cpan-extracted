use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl class for reading a graph from OID format.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Graph-Reader-OID';
readme_from 'OID.pm';
recursive_author_tests('xt');
requires 'Graph::Reader' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Graph-Reader-OID/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Graph-Reader-OID';
resources 'repository' => 'git://github.com/michal-josef-spacek/Graph-Reader-OID';
test_requires 'File::Object' => 0.07;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
