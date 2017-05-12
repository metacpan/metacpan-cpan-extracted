#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 7;
use Data::Dump qw/dump/;

BEGIN {
	use_ok( 'MARC::Fast' );
	use_ok( 'Encode' );
}

my $debug = shift @ARGV;

my $marc_file = 't/utf8.marc';

ok(my $marc = MARC::Fast->new(
	marcdb => $marc_file,
	hash_filter => sub {
		Encode::decode( 'utf-8', $_[0] );
	},
), "new");

cmp_ok($marc->count, '==', 1, 'count' );

ok(my $rec = $marc->fetch(1), "fetch 1");
diag dump $rec if $debug;

ok(my $hash = $marc->to_hash(1), "to_hash 1");
diag dump $hash if $debug;

ok( $hash->{260}->[0]->{'b'} eq "\x{160}kolska knjiga,", 'utf-8 flag' );

