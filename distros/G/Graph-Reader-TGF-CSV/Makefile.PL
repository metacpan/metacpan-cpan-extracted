# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Perl class for reading a graph from TGF format with CSV labeling.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Graph-Reader-TGF-CSV';
readme_from 'CSV.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.16;
requires 'Graph::Reader::TGF' => 0.01;
requires 'Text::CSV' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Graph-Reader-TGF-CSV';
resources 'homepage' => 'https://github.com/tupinek/Graph-Reader-TGF-CSV';
resources 'repository' => 'git://github.com/tupinek/Graph-Reader-TGF-CSV';
test_requires 'Encode' => 0;
test_requires 'English' => 0;
test_requires 'File::Object' => 0.07;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
