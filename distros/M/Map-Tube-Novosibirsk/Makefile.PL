# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Interface to the Novosibirsk Metro Map.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_share 'share';
license 'bsd';
license 'artistic_2';
name 'Map-Tube-Novosibirsk';
readme_from 'Novosibirsk.pm';
recursive_author_tests('xt');
requires 'File::Share' => 0;
requires 'Map::Tube' => '3.06';
requires 'Moo' => 0;
requires 'namespace::clean' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Map-Tube-Novosibirsk';
resources 'homepage' => 'https://github.com/tupinek/Map-Tube-Novosibirsk';
resources 'repository' => 'git://github.com/tupinek/Map-Tube-Novosibirsk';
test_requires 'Encode' => 0;
test_requires 'English' => 0;
test_requires 'Test::Map::Tube' => 0.06;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
