#!/usr/bin/env perl
use inc::Module::Install;

name 'JSORB';
all_from 'lib/JSORB.pm';

requires 'Moose'                      => 0;
requires 'MooseX::AttributeHelpers'   => 0;
requires 'MooseX::Traits'             => '0.06';
requires 'MooseX::Params::Validate'   => 0;

requires 'Try::Tiny'                  => 0;
requires 'Set::Object'                => 0;
requires 'JSON::RPC::Common'          => '0.05';
requires 'Path::Router'               => 0;

# for the JSORB::Client::Compiler
requires 'Buffer::Transactional'      => 0;
requires 'MooseX::Types::Path::Class' => 0;

# for the JSORB.pm client library
requires 'Class::Inspector'           => 0;
requires 'File::Copy'                 => 0;

# for the JSORB.js client library
requires 'JS'                         => 0;
requires 'JS::JSON'                   => 0;
requires 'JS::jQuery'                 => 0;

# for JSORB::Server::Simple
requires 'HTTP::Server::Simple'       => 0.34;
requires 'HTTP::Request'              => 0;
requires 'HTTP::Response'             => 0;

# for JSORB::Server::Traits::WithStaticFiles
#requires 'MooseX::Types::Path::Class' => 0;

# for JSORB::Server::Traits::WithDebug
requires 'Text::SimpleTable'          => 0;

# for Catalyst::Action::JSORB
feature 'Catalyst support',
    -default   => 0,
    'Catalyst' => 0;

# for testing
build_requires 'Test::More'           => 0;
build_requires 'Test::WWW::Mechanize' => 0;

# for JS testing
build_requires 'JS::Test::Base'       => 0;

WriteAll;
