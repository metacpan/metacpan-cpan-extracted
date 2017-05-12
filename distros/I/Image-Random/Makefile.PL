# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Perl class for creating random image.';
author 'Michal Spacek <skim@cpan.org>';
license 'bsd';
name 'Image-Random';
readme_from 'Random.pm';
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0.11;
requires 'File::Basename' => 0;
requires 'Imager' => 0;
requires 'Imager::Color' => 0;
requires 'List::MoreUtils' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Image-Random';
resources 'homepage' => 'https://github.com/tupinek/Image-Random';
resources 'repository' => 'git://github.com/tupinek/Image-Random';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
