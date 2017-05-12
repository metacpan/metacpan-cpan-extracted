#!/usr/bin/perl -wT
# Iperntiy::API test suite
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id$
# Last modified: [ 2010-12-05 14:32:21 ]

use Test::More tests => 2;
use lib ( 'blib/lib', 'lib/', 'lib/Ipernity' );
use Ipernity::API;

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
