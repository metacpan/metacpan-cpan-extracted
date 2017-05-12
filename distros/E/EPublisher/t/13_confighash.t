#!/usr/bin/perl

use Test::More tests => 4;
use File::Spec;
use File::Basename;

my $module = 'EPublisher';
use_ok( $module );

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );
unshift @INC, File::Spec->catdir( $dir, 'lib' );

my $check = {
   Test => {
      source   => {
         type => 'File',
         path => './t/01_base.t',
      },
      target => {
         type => 'Text',
         output => './t/text.txt',
      },
   }
};

my $obj = EPublisher->new( config => $check );
isa_ok( $obj, $module );

$obj->run( ['Test'] );

my $res  = $obj->_config;
delete $res->{Test}->{target}->{source};

ok -e $check->{Test}->{target}->{output};
is_deeply( $res, $check, 'check configuration' );

unlink $check->{Test}->{target}->{output};
