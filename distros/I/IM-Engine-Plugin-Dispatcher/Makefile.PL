use inc::Module::Install;

name     'IM-Engine-Plugin-Dispatcher';
all_from 'lib/IM/Engine/Plugin/Dispatcher.pm';
githubmeta;

requires 'Moose';
requires 'IM::Engine' => 0.03;
requires 'Path::Dispatcher' => 0.13;

tests('t/*.t t/*/*.t');

auto_install;
WriteAll;

