#!/usr/bin/perl
use Test::More;
use lib 'lib';
use Module::Pluggable search_path => [ 'Measure::Everything' ];

require_ok( $_ ) for sort __PACKAGE__->plugins;

done_testing();
