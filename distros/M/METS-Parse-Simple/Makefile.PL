use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'METS parse class.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'METS-Parse-Simple';
readme_from 'Simple.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'XML::Simple' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=METS-Parse-Simple';
resources 'homepage' => 'https://github.com/michal-josef-spacek/METS-Parse-Simple';
resources 'repository' => 'git://github.com/michal-josef-spacek/METS-Parse-Simple';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
