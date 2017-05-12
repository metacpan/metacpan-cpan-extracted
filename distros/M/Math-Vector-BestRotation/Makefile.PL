use inc::Module::Install;

name     'Math-Vector-BestRotation';
all_from 'lib/Math/Vector/BestRotation.pm';
author   q{Lutz Gehlen <perl@lutzgehlen.de>};
license  'perl';

requires 'Math::MatrixReal' => '2.05';
requires 'Carp'             => '1.08';

build_requires 'Test::More';

auto_install;

WriteAll;

