#!/usr/bin/perl

=pod

=head1 Testcase

05_sources.t - test for the source plugins

=cut

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 5; 
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
      title => 'My EBook',
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::File' ), '$source isa EPublisher::Source::Plugin::File' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my $info = $source->load_source;
   ok( $source->load_source, 'check *::File::load_source()' );

   my $check = {
       pod => '=pod

=head1 Testcase

05_sources.t - test for the source plugins

=cut
',
       filename => '12_source_file_arbitrary_title.t',
       title => 'My EBook',
   };
   
   is_deeply( $info, $check, 'check return value of *::File::load_source()' );
}

