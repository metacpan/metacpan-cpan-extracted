#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('LogicMonitor::REST::Signature');
}

my $company   = 'foo';
my $accessKey = 'some key';
my $accessID  = 'some ID';

# make sure it errors when undef or missing values
my $worked = 0;
my $lmsig_helper;
eval {
	$lmsig_helper = LogicMonitor::REST::Signature->new( {} );
	$worked       = 1;
};
ok( $worked eq '0', 'init' ) or diag("Iinitated with missing values");

# make sure we init it
$worked = 0;
eval {
	$lmsig_helper = LogicMonitor::REST::Signature->new(
		{
			accessKey => $accessKey,
			accessID  => $accessID,
		}
	);
	$worked = 1;
};
ok( $worked eq '1', 'init' ) or diag( "Failed to init the object... " . $@ );

# make sure it can generate a known one, which requires a time stamp
$worked = 0;
eval {
	my $sig = $lmsig_helper->signature(
		{
			HTTPverb  => 'GET',
			path      => '/foo',
			data      => '',
			timestamp => '1',
		}
	);
	if ( $sig ne 'N2I0NmRiZTRlMTEyMGRlNDFkMzJmYjQ5Y2I1MzZiZThkOGVlZWNkNzdkNmIxNTU3MWQ0ODRjNDIzOGMwZGRmZQ==' ) {
		die 'Got "' . $sig
			. '" but was expecting "N2I0NmRiZTRlMTEyMGRlNDFkMzJmYjQ5Y2I1MzZiZThkOGVlZWNkNzdkNmIxNTU3MWQ0ODRjNDIzOGMwZGRmZQ=="';
	}
	$worked = 1;
};
ok( $worked eq '1', 'signature 0' ) or diag( "Failed to create the expected signature... " . $@ );

# make sure it can generate a known one with no data, which requires a time stamp
$worked = 0;
eval {
	my $sig = $lmsig_helper->signature(
		{
			HTTPverb  => 'GET',
			path      => '/foo',
			timestamp => '1',
		}
	);
	if ( $sig ne 'N2I0NmRiZTRlMTEyMGRlNDFkMzJmYjQ5Y2I1MzZiZThkOGVlZWNkNzdkNmIxNTU3MWQ0ODRjNDIzOGMwZGRmZQ==' ) {
		die 'Got "' . $sig
			. '" but was expecting "N2I0NmRiZTRlMTEyMGRlNDFkMzJmYjQ5Y2I1MzZiZThkOGVlZWNkNzdkNmIxNTU3MWQ0ODRjNDIzOGMwZGRmZQ=="';
	}
	$worked = 1;
};
ok( $worked eq '1', 'signature 1' ) or diag( "Failed to create the expected signature... " . $@ );

# tests if it can call auth_header and generate a valid signature
$worked = 0;
eval {
	my $auth_header = $lmsig_helper->auth_header(
		{
			HTTPverb => 'GET',
			path     => '/foo',
			data     => '',
		}
	);
	if ( $auth_header !~ /^LMv1\ .*\:[a-zA-Z0-9\+\/\=]*:[0-9]+$/ ) {
		die 'Got "' . $auth_header . '" but was expecting "e0bb5OESDeQdMvtJy1Nr6Nju7Nd9axVXHUhMQjjA3f4="';
	}
	$worked = 1;
};
ok( $worked eq '1', 'auth_header 0' ) or diag( "Failed to create a auth_header... " . $@ );

done_testing(6);
