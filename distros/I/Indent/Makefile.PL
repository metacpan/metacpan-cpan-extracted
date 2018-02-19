use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Classes for indent handling.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Indent';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0.08;
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'Text::ANSI::Util' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Indent';
resources 'homepage' => 'https://github.com/tupinek/Indent';
resources 'repository' => 'git://github.com/tupinek/Indent';
test_requires 'English' => 0;
test_requires 'Term::ANSIColor' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Text::ANSI::Util' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
