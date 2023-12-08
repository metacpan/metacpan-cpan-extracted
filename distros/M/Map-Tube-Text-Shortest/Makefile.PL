use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Shortest route information via Map::Tube object.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
license 'artistic_2';
name 'Map-Tube-Text-Shortest';
readme_from 'Shortest.pm';
requires 'Class::Utils' => 0.06;
requires 'Error::Pure' => 0.21;
requires 'List::Util' => 0;
requires 'Scalar::Util' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Map-Tube-Text-Shortest/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Map-Tube-Text-Shortest';
resources 'repository' => 'git://github.com/michal-josef-spacek/Map-Tube-Text-Shortest';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Map::Tube::Prague' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
