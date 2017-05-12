#! /usr/bin/perl

use Test::More;
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { } );

# Force an adapter to be created
require Log::Any;
my $log= Log::Any->get_logger(category => 'test1');
ok( !$log->is_debug );

# Init should have been called once, now.
# Ensure it does not get auto-called when creating new adapters;

my $called_again= 0;
local *Log::Any::Adapter::Daemontools::Config::init= sub { ++$called_again; };

# Force another adapter to be created
my $log2= Log::Any->get_logger(category => 'test2');
ok( !$log->is_debug );

# now check our count
is( $called_again, 0, 'init() not called again' );

done_testing;
