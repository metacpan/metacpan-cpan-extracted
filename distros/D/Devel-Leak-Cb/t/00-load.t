#!/usr/bin/env perl

use common::sense;
use lib::abs '../lib';
use Test::More tests => 1;

BEGIN {
	use_ok( 'Devel::Leak::Cb' );
}

diag( "Testing Devel::Leak::Cb $Devel::Leak::Cb::VERSION, Perl $], $^X" );
