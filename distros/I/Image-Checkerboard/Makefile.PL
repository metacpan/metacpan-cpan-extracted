use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl class for image checkerboards creating.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Image-Checkerboard';
readme_from 'Checkerboard.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.06;
requires 'Error::Pure' => 0.17;
requires 'Imager' => 0;
requires 'Imager::Fill' => 0;
requires 'List::MoreUtils' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Image-Checkerboard';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Image-Checkerboard';
resources 'repository' => 'git://github.com/michal-josef-spacek/Image-Checkerboard';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
