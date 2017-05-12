use inc::Module::Install 0.75;

name     'Layout-Manager';
all_from 'lib/Layout/Manager.pm';
author   'Cory G Watson <gphat@cpan.org>';

build_requires 'Test::More';

requires 'Moose' => '0.79';
requires 'Geometry::Primitive' => '0.16';
requires 'Graphics::Primitive' => '0.43';

tests_recursive;

WriteAll;

