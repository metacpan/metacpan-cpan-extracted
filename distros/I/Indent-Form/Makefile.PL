use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'A perl module for form indenting.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Indent-Form';
readme_from 'Form.pm';
requires 'Class::Utils' => 0.05;
requires 'English' => 0;
requires 'Error::Pure' => 0.16;
requires 'Indent::Word' => 0.04;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Indent-Form/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Indent-Form';
resources 'repository' => 'git://github.com/michal-josef-spacek/Indent-Form';
test_requires 'Encode' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0.08;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
