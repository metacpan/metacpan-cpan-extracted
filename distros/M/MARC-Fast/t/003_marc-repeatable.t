#!/usr/bin/perl -w

use strict;
use lib 'lib';

use Test::More tests => 8;
use Data::Dump qw/dump/;

BEGIN {
	use_ok( 'MARC::Fast' );
	use_ok( 'Encode' );
}

my $debug = shift @ARGV;

my $marc_file = 't/koha-232766.mrc';

ok(my $marc = MARC::Fast->new(
	marcdb => $marc_file,
), "new");

cmp_ok($marc->count, '==', 1, 'count' );

ok(my $rec = $marc->fetch(1), "fetch 1");
diag dump $rec if $debug;

ok(my $hash = $marc->to_hash(1, include_subfields => 1), "to_hash 1 include_subfields");
diag dump $hash if $debug;

ok( ref $hash->{653}->[0]->{'a'} eq '', 'first occurance not repeatable' );
ok( ref $hash->{653}->[1]->{'a'} eq 'ARRAY', 'second is repetable' );

