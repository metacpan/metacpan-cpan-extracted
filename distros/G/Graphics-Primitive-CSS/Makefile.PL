use inc::Module::Install;

name     'Graphics-Primitive-CSS';
all_from 'lib/Graphics/Primitive/CSS.pm';
author   'Cory G Watson <gphat@cpan.org>';
license  'perl';

build_requires 'Test::More';

requires 'Check::ISA'           => 0.04;
requires 'CSS::DOM'             => 0.06;
requires 'Graphics::Color'      => 0.23;
requires 'Graphics::Primitive'  => 0.44;
requires 'Moose'                => 0.87;

WriteAll;

