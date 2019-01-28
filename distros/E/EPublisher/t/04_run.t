#!/usr/bin/perl

use Test::More tests => 7;
use File::Spec;
use File::Basename;

my $module = 'EPublisher';
use_ok( $module );

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );
unshift @INC, File::Spec->catdir( $dir, 'lib' );

my $config_dir = File::Spec->catdir( $dir, 'config' );

my @methods = qw(new config run);
can_ok( $module, @methods );
my $obj = EPublisher->new;
isa_ok( $obj, $module );

my $yaml = File::Spec->catfile( $config_dir, 'base.yml' );
$obj->config( $yaml );
is( $obj->config, $yaml, 'set config file' );

$obj->run( ['Test'] );

my $obj2 = $module->new( config => $yaml );
my $res  = $obj2->_config;

my $check = {
   Test => {
      source   => {
         type => 'File',
         path => './t/03_base_source.t',
      },
      target => {
         type => 'Text',
         output => './t/text.txt',
      },
   }
};

ok -e $check->{Test}->{target}->{output};
is_deeply( $res, $check, 'check configuration' );

unlink $check->{Test}->{target}->{output};

{
   require EPublisher::Config;
   my $obj = bless {}, 'EPublisher';
   
   $obj->{_configfile} = File::Spec->catfile( $config_dir, 'run_3.yml' );
   $obj->{__config} = {};
   $obj->_config(1);
   
   my $check = {
      Test => {
         source => {
            type => 'ReneePC',
            path => './t/scripts/mb_test.pl',
         },
         target => {
            type => 'Dummy',
         },
      },
   };
   
   is_deeply( $obj->_config, $check, 'Object configuration' );
}
