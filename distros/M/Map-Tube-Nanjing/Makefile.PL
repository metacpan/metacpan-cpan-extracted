use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Interface to the Nanjing Metro Map.';
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
name 'Map-Tube-Nanjing';
readme_from 'Nanjing.pm';
recursive_author_tests('xt');
requires 'File::Share' => 0;
requires 'Map::Tube' => '3.62';
requires 'Moo' => 0;
requires 'namespace::clean' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Map-Tube-Nanjing';
resources 'homepage' => 'https://github.com/tupinek/Map-Tube-Nanjing';
resources 'repository' => 'git://github.com/tupinek/Map-Tube-Nanjing';
test_requires 'Encode' => 0;
test_requires 'English' => 0;
test_requires 'Test::Map::Tube' => 0.07;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
