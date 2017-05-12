#!/usr/bin/perl

use File::Basename;
use File::Spec;
use Test::More tests => 4;

my $module = 'EPublisher';
use_ok( $module );

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );

my @methods = qw(new config run);
can_ok( $module, @methods );
my $obj = EPublisher->new;
isa_ok( $obj, $module );

eval{
   my $obj2 = $module->new;
   $obj2->_config;
};

like( $@, qr/no config file given/, 'no config file given' );