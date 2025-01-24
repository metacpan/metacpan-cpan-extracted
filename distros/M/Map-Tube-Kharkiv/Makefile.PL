use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Interface to the Kharkiv Metro Map.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_share 'share';
license 'bsd';
license 'artistic_2';
name 'Map-Tube-Kharkiv';
readme_from 'Kharkiv.pm';
recursive_author_tests('xt');
requires 'File::Share' => 0;
requires 'Map::Tube' => '3.62';
requires 'Moo' => 0;
requires 'namespace::clean' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Map-Tube-Kharkiv/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Map-Tube-Kharkiv';
resources 'repository' => 'git://github.com/michal-josef-spacek/Map-Tube-Kharkiv';
test_requires 'Encode' => 0;
test_requires 'English' => 0;
test_requires 'Test::Map::Tube' => 0.35;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
