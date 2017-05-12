use inc::Module::Install;

name     'Graphics-Primitive-Driver-GD';
all_from 'lib/Graphics/Primitive/Driver/GD.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'GD' => '2.44';
requires 'Graphics::Primitive' => '0.47';
requires 'Math::Complex' => '1.56';
requires 'Text::Flow' => '0.01';

WriteAll;

