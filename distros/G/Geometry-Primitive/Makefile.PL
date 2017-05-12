use inc::Module::Install 0.75;

name     'Geometry-Primitive';
all_from 'lib/Geometry/Primitive.pm';
author   'Cory Watson <gphat@cpan.org>';

build_requires 'Test::More';

test_requires 'JSON::Any' => '1.22';

requires 'Check::ISA' => '0.04';
requires 'Math::Complex' => '1.56';
requires 'Moose' => '0.92';
requires 'MooseX::Clone' => '0.04';
requires 'MooseX::Storage' => '0.23';

WriteAll;

