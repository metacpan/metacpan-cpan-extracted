#!/usr/bin/perl -wT
# Iperntiy::API test suite
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id$
# Last modified: [ 2010-12-05 14:32:21 ]

use Test::More tests => 7;
use lib ( 'blib/lib', 'lib/', 'lib/Ipernity' );
use Ipernity::API;
use IO::Socket::INET;

## Define Ipernity::API object {{{
my $api = Ipernity::API->new(

	'api_key'	=> '76704c8b0000271B6df755a656250e26',
	'outputformat'	=> 'xml',

);
# }}}

## Check if object has been defined {{{
ok( defined( $api ), 'Ipernity::API object successfully created' );
ok( $api->isa( 'Ipernity::API' ), 'Object is an Ipernity::API object' );
# }}}

## Check for internet connectivity {{{
pass( 'Checking if internet connectivity is given' );
my $inet = IO::Socket::INET->new(

	'PeerAddr'	=> 'www.google.com:80',
	'Timeout'	=> 3,
	'Proto'		=> 'tcp',

);
# }}}

## Execute API call (skip if user doesn't have internet connectivity) {{{
SKIP: {

	## Define skip condition
	skip( '// Not internet connectivity given', 4 ) unless( defined( $inet ) and $inet );

	## If connectivity is given, we can close the FH now
	pass( 'Internet connectivity is given' );

	## Send test.hello API call {{{
	my $hello = $api->execute_hash(

		'method'	=> 'test.hello',

	);
	# }}}

	## Check if API response is ok {{{
	ok( defined( $hello ), 'test.hello API call produced an answer' );
	is( $hello->{ 'status' }, 'ok', 'Ipernity API status is \'ok\'' );
	is( $hello->{ 'hello' }->[0]->{ 'content' }, 'hello world!', 'Ipernity API anwered with "hello world!"' );
	# }}}
	
}
# }}}
