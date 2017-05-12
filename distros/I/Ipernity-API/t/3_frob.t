#!/usr/bin/perl -wT
# Iperntiy::API test suite
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id$
# Last modified: [ 2010-12-05 14:32:21 ]

use Test::More tests => 4;
use lib ( 'blib/lib', 'lib/', 'lib/Ipernity' );
use Ipernity::API;

## Define Ipernity::API object {{{
my $api = Ipernity::API->new(

	'api_key'	=> '76704c8b0000271B6df755a656250e26',
	'secret'	=> '44879417fa431810',
	'outputformat'	=> 'xml',

);
# }}}

## Retrieve a API frob {{{
my $frob = $api->fetchfrob();
# }}}

## Check if object has been defined and frob was fetched {{{
ok( defined( $api ), 'Ipernity::API object successfully created' );
ok( $api->isa( 'Ipernity::API' ), 'Object is an Ipernity::API object' );
ok( defined( $frob ), 'Frob has been successfully fetched' );
like( $frob, qr/(\d+|\w+)-(\d+|\w+)/, 'API response looks like a frob' );
# }}}
