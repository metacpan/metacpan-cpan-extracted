use lib '.';
use strict;
use warnings;

use English;
use inc::Module::Install;

# Definition.
abstract 'GraphViz interface to the Map::Tube.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
license 'artistic_2';
name 'Map-Tube-GraphViz';
readme_from 'GraphViz.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => '0.06';
requires 'Error::Pure' => '0.21';
requires 'Exporter' => 0;
requires 'GraphViz2' => 2.59;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'Scalar::Util' => 0;
if ($PERL_VERSION lt v5.10.1) {
	requires 'UNIVERSAL::DOES' => 0;
}
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Map-Tube-GraphViz';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Map-Tube-GraphViz';
resources 'repository' => 'git://github.com/michal-josef-spacek/Map-Tube-GraphViz';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'File::Object' => 0.08;
test_requires 'Map::Tube::Prague' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
