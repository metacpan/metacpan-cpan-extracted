use inc::Module::Install;

name     'Graphics-Primitive-Driver-CairoPango';
all_from 'lib/Graphics/Primitive/Driver/CairoPango.pm';
author   'Cory G Watson <gphat@cpan.org>';

build_requires 'Test::More';

test_requires 'File::Spec';

requires 'Cairo' => '1.061';
requires 'Pango' => '1.220';
requires 'Moose' => '0.79';
requires 'IO::File';
requires 'Geometry::Primitive' => '0.13';
requires 'Graphics::Primitive' => '0.45';
requires 'Graphics::Primitive::Driver::Cairo' => '0.38';
requires 'Math::Complex' => '1.56';

WriteAll;

