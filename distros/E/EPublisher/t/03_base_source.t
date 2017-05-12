#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 4;
use File::Basename;
use File::Spec;
use lib qw(../lib ../../perllib);

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );

my $module = 'EPublisher::Source';
use_ok( $module );

{
   # test EPublisher::Source::Plugin::File
   my $source = $module->new({
      type => 'File',
      path => __FILE__, 
   });
   ok( $source->isa( 'EPublisher::Source::Plugin::File' ), '$source isa EPublisher::Source::Plugin::File' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );
   
   ok( $source->load_source, 'check *::File::load_source()' );
}

=head1 A unit test
