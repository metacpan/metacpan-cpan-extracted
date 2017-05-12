use inc::Module::Install;

name     'JavaScript-Framework-jQuery';
all_from 'lib/JavaScript/Framework/jQuery.pm';
author   'David P.C. Wollmann <converter42 at gmail.com>';
license  'perl';

build_requires 'Test::More';

requires 'Moose', '0.77';
requires 'MooseX::Types', '0.10';
requires 'MooseX::Types::Moose';
requires 'MooseX::Types::Structured', '0.14';
requires 'MooseX::Params::Validate', '0.09';
requires 'JSON', '2.12';

auto_install;

WriteAll;

