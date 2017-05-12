#!/usr/bin/perl

=pod

05_sources.t - test for the source plugins

=cut

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 9; 
use File::Basename;
use File::Spec;
use lib qw(../lib ../../perllib);
use YAML::Tiny;

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );

my $module = 'EPublisher::Source';
use_ok( $module );

{
   my $source = $module->new({
      type => 'File',
      path => __FILE__,
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::File' ), '$source isa EPublisher::Source::Plugin::File' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my $info = $source->load_source;
   ok( $source->load_source, 'check *::File::load_source()' );

   my $check = {
       pod => '=pod

05_sources.t - test for the source plugins

=cut
',
       filename => '09_source_file.t',
       title => '09_source_file.t',
   };
   
   is_deeply( $info, $check, 'check return value of *::File::load_source()' );
}

{
   my $source = $module->new({
      type => 'File',
      path => __FILE__,
      title => 'pod',
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::File' ), '$source isa EPublisher::Source::Plugin::File' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my $info = $source->load_source;
   ok( $source->load_source, 'check *::File::load_source()' );

   my $check = {
       pod => '=pod

05_sources.t - test for the source plugins

=cut
',
       filename => '09_source_file.t',
       title => '',
   };
   
   is_deeply( $info, $check, 'check return value of *::File::load_source()' );
}

