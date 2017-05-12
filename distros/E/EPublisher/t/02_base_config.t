#!/usr/bin/perl

use Test::More tests => 5;
my $module = 'EPublisher::Config';

use_ok( $module );

my @functions = qw( get_config );
can_ok( $module, @functions );

my $file = './t/config/test_config.yml';
my $config = EPublisher::Config->get_config( $file );
is( $file, $config->{filename} );

my $check = {
   filename => './t/config/test_config.yml',
};

is_deeply( $config, $check, 'test structure' );

eval{
   my $test = EPublisher::Config->get_config;
};
like( $@, qr/No .+ config file given/, 'No file given' );