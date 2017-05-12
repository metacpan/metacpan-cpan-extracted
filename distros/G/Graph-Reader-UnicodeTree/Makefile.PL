# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Perl class for reading a graph from unicode tree text format.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Graph-Reader-UnicodeTree';
readme_from 'UnicodeTree.pm';
recursive_author_tests('xt');
requires 'Encode' => 0;
requires 'Graph::Reader' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Graph-Reader-UnicodeTree';
resources 'homepage' => 'https://github.com/tupinek/Graph-Reader-UnicodeTree';
resources 'repository' => 'git://github.com/tupinek/Graph-Reader-UnicodeTree';
test_requires 'Encode' => 0;
test_requires 'File::Object' => 0.07;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
