use strict;
use warnings;
use inc::Module::Install;

name 'IO-ReStoreFH';
author 'Diab Jerius';
license 'gpl3';
all_from 'lib/IO/ReStoreFH.pm';

repository 'http://bitbucket.org/djerius/io-restorefh';
bugtracker 'https://rt.cpan.org/Public/Dist/Display.html?Name=IO-ReStoreFH';

author_tests( 'xt' );

test_requires 'Test::More', 0.96;
test_requires 'Test::File::Contents', 0.20;
test_requires 'Test::Exception';

author_requires 'Test::NoBreakpoints';
auto_install;

requires 'FileHandle::Fmode', 0.12;
requires 'Try::Tiny';

WriteAll;
