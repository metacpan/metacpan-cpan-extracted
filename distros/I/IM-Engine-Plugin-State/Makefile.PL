use inc::Module::Install;

name     'IM-Engine-Plugin-State';
all_from 'lib/IM/Engine/Plugin/State.pm';
githubmeta;

requires 'Moose';
requires 'MooseX::ABC' => 0.02;

requires 'IM::Engine' => 0.03;

test_requires 'Test::Exception';

tests('t/*.t t/*/*.t');

auto_install;
WriteAll;

