#!/usr/bin/perl
use strict;
use warnings;
use lib 'mbk';
use Module::Build::Kwalitee;
Module::Build::Kwalitee->new(
  module_name => 'Froody',
  license     => 'perl',
  requires    => {
    'perl' => 5.008,
    'Class::Accessor::Chained::Fast' => 0,
    'Class::Data::Inheritable' => 0,
    'HTTP::Server::Simple' => 0,
    'HTTP::Date' => 0,
    'URI' => 0,
    'Error' => '0.15',
    'Email::Valid' => 0,
    'File::Spec' => 0,
    'Params::Validate' => 0,
    'XML::LibXML' => 0,
    'UNIVERSAL::require' => 0,
    'LWP::Simple' => 0,
    'LWP::UserAgent' => 0,
    'HTTP::Request::Common' => 0,
    'Template' => 0,
    'List::MoreUtils' => 0,
    'YAML::Syck' => 0,
    'Module::Pluggable' => 0,
  },
  recommends => {
    'Apache' => 0,
    'Apache::Request' => 0,
    'Apache::Cookie' => 0,
    'Apache::Constants' => 0,
    'Logger' => 0,	 # a Fotango-specific Log4perl wrapper
    'Test::Logger' => 0, # provided by Logger
    'PPI' => 0,
    'File::Find::Rule' => 0,
    'JavaScript::Standalone' => 0,
  },
  build_requires => {
    'Test::More' => 0,
    'Test::Exception' => 0,
    'Test::Differences' => 0,
    'Test::XML' => 0,
  },
  script_files => [qw(
    bin/froody
    bin/froodydoc
    bin/find_froody_exceptions
  )],
  create_readme => 1,
  create_makefile_pl => 'traditional',
  recursive_test_files => 1,
)->create_build_script();
