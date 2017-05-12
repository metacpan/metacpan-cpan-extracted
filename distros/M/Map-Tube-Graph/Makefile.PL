# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use inc::Module::Install;

# Definition.
abstract 'Graph interface to the Map::Tube.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
license 'artistic_2';
name 'Map-Tube-Graph';
readme_from 'Graph.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.06;
requires 'Error::Pure' => 0.22;
requires 'Graph' => 0.9702;
requires 'List::MoreUtils' => 0;
requires 'Scalar::Util' => 0;
if ($PERL_VERSION lt v5.10.1) {
	requires 'UNIVERSAL::DOES' => 0;
}
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Map-Tube-Graph';
resources 'homepage' => 'https://github.com/tupinek/Map-Tube-Graph';
resources 'repository' => 'git://github.com/tupinek/Map-Tube-Graph';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'Graph::Undirected' => 0;
test_requires 'Map::Tube::Prague' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
