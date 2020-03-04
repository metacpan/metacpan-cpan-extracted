use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl class for creating random image.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
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
resources 'homepage' => 'https://github.com/michal-josef-spacek/Image-Random';
resources 'repository' => 'git://github.com/michal-josef-spacek/Image-Random';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'Filesys::POSIX' => 0;
test_requires 'Filesys::POSIX::Mem' => 0;
test_requires 'Imager::File::JPEG' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
