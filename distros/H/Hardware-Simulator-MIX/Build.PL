#!/usr/bin/perl

use warnings;

use strict;

use Module::Build;



my $build=Module::Build->new
  (
   
module_name => 'Hardware::Simulator::MIX',
   
license => 'perl',
   
dist_author => 'Chaoji Li <lichaoji@ict.ac.cn>',

dist_abstract => 'MIX simulator, with timing added',
   build_requires => {'Test::More'=>0},
   requires => {},
   create_makefile_pl => 'traditional' # don't require having Module::Build for end-users
  )->create_build_script;
