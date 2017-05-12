# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Process environment variable $BROWSER and run web browser.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.06;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Env-Browser';
readme_from 'Browser.pm';
recursive_author_tests('xt');
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Env-Browser';
resources 'homepage' => 'https://github.com/tupinek/Env-Browser';
resources 'repository' => 'git://github.com/tupinek/Env-Browser';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 1.02;
tests_recursive;
version '0.05';

# Run.
WriteAll();
