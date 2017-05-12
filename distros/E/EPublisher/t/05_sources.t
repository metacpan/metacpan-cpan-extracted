#!/usr/bin/perl

=pod

05_sources.t - test for the source plugins

=cut

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 8;
use File::Basename;
use File::Spec;
use YAML::Tiny;

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );

my $module = 'EPublisher::Source';
use_ok( $module );

#
# Module
###
{
   # test EPublisher::Source::Plugin::Module
   my $source = $module->new({
      type => 'Module',
      name => 'File::Temp', 
   });
   ok( $source->isa( 'EPublisher::Source::Plugin::Module' ), '$source isa EPublisher::Source::Plugin::Module' );
   ok( $source->isa( 'EPublisher::Source::Base' ),           '$source isa EPublisher::Source::Base' );
   
   ok( $source->load_source, 'check *::Module::load_source()' );
}

#
# File
###
{
   my $source = $module->new({
      type => 'File',
      path => __FILE__,
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::File' ), '$source isa EPublisher::Source::Plugin::File' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );
   
   ok( $source->load_source, 'check *::File::load_source()' );
}

#
# Force Error
###
{
   eval{
      my $source = $module->new({
         type => 'AnyNonExistentTargetPlugin',
      });
   };
   
   like( $@, qr/Problems with/, 'Force error' );
}
