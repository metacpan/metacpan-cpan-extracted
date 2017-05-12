#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 9;
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
		my ($l, $tag) = @_;
		$l = Encode::decode( 'utf-8', $l );
		$l =~ s/knjiga/briga/;
		return $l;
	},
), "new");

cmp_ok($marc->count, '==', 1, 'count' );

ok(my $rec = $marc->fetch(1), "fetch 1");
diag dump $rec if $debug;

ok(my $hash = $marc->to_hash(1), "to_hash 1");
diag dump $hash if $debug;

cmp_ok( $hash->{260}->[0]->{'b'}, 'eq', "\x{160}kolska briga,", 'hash_filter from new' );

ok($hash = $marc->to_hash(1, hash_filter => sub {
		my ($l, $tag) = @_;
		$l = Encode::decode( 'utf-8', $l );
		$l =~ s/knjiga/zabava/;
		return $l;
}), "to_hash 1 with hash_filter");
diag dump $hash if $debug;

cmp_ok( $hash->{260}->[0]->{'b'}, 'eq', "\x{160}kolska zabava,", 'hash_filter from to_hash' );
