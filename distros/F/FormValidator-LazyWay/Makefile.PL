use strict;
use warnings;
use inc::Module::Install;

name 'FormValidator-LazyWay';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
requires 'Class::Accessor::Fast'      => 0;
requires 'Data::Validate::URI'        => 0;
requires 'DateTime::Format::Strptime' => 0;
requires 'Email::Valid'               => 0;
requires 'Email::Valid::Loose'        => 0;
requires 'Perl6::Junction'            => 0;
requires 'UNIVERSAL::require'         => 0;
requires 'URI'                        => 0;

build_requires 'Test::Base'         => 0;
build_requires 'Test::Base::Filter' => 0;
build_requires 'Test::Exception'    => 0;
build_requires 'YAML'               => 0;
build_requires 'YAML::Syck'         => 0;

all_from 'lib/FormValidator/LazyWay.pm';

auto_install;

auto_set_repository;

WriteAll;
