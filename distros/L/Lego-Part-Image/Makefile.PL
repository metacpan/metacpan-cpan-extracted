use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Lego part image objects.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Lego-Part-Image';
readme_from 'Image.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0.22;
requires 'Readonly' => 0;
requires 'Scalar::Util' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Lego-Part-Image/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Lego-Part-Image';
resources 'repository' => 'git://github.com/michal-josef-spacek/Lego-Part-Image';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'Lego::Part' => 0.01;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
