#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Log::Any '$log';
use FindBin;
use lib "$FindBin::Bin/lib";
use TestLogging;

my @warnings;
local $SIG{__WARN__}= sub { push @warnings, @_ };

$ENV{TAP_LOG_FILTER}= 'foo54321';
note "Test that invalid global log filter can't crash it";
use_ok( 'Log::Any::Adapter', 'TAP' );
is( scalar @warnings, 1, 'got warning' )
	and like( $warnings[0], qr/foo54321/, 'warning about foo' );

try {
	Log::Any::Adapter->set( 'TAP', filter => 'emergency+2' );
	my $cls1= ref $log;
	Log::Any::Adapter->set( 'TAP', filter => 'all' );
	is( $cls1, ref $log, 'filter was capped' );
} catch {
	diag $_;
	fail 'set level emergency+2';
};

done_testing;
