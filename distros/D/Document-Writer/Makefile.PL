use inc::Module::Install;

name     'Document-Writer';
all_from 'lib/Document/Writer.pm';
author   'Cory G Watson <gphat@cpan.org>';

build_requires 'Test::More';

test_requires 'Pod::Coverage::Moose';

requires 'Forest' => '0.06';
requires 'Graphics::Primitive' => '0.39';
requires 'Layout::Manager' => '0.20';
requires 'Moose' => '0.72';
requires 'MooseX::AttributeHelpers' => '0.14';
requires 'Paper::Specs' => '0.10';

WriteAll;

