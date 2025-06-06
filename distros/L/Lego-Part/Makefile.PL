use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Lego part object.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Lego-Part';
readme_from 'Part.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'English' => 0;
requires 'Error::Pure' => 0.22;
requires 'Scalar::Util' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Lego-Part/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Lego-Part';
resources 'repository' => 'git://github.com/michal-josef-spacek/Lego-Part';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
