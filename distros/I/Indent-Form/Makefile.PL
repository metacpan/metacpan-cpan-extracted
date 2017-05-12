# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'A perl module for form indenting.';
author 'Michal Špaček <skim@cpan.org>';
license 'bsd';
name 'Indent-Form';
readme_from 'Form.pm';
requires 'Class::Utils' => 0.05;
requires 'English' => 0;
requires 'Error::Pure' => 0.16;
requires 'Indent::Word' => 0.03;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Indent-Form';
resources 'homepage' => 'https://github.com/tupinek/Indent-Form';
resources 'repository' => 'git://github.com/tupinek/Indent-Form';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.08;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
