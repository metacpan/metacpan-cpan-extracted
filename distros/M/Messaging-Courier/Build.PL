#!/usr/bin/perl
use warnings;
use strict;
use Module::Build;

Module::Build->new(
  create_makefile_pl => 'traditional',
  license     => 'perl',
  module_name => 'Messaging::Courier',
  requires    => {
    'Spread'          => '0.01',
    'Term::ReadKey'   => '0.01',
    'Data::UUID'      => '0.01',
    'DateTime'        => '0.01',
    'XML::LibXML'     => '0.01',
    'Clone'           => '0.01',
    'File::HomeDir'   => '0.01',
    'Regexp::Common'  => '0.01',
    'Test::Exception' => '0.01',
    'Class::Accessor::Chained' => '0.01',
    'XML::asData'     => 0,
  },
)->create_build_script;
