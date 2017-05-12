#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 63;
use Data::Dump qw/dump/;

BEGIN {
	use_ok( 'MARC::Fast' );
}

my $debug = shift @ARGV;

my $marc_file = 't/camel.usmarc';

my $marc;
my %param;

eval { $marc = MARC::Fast->new(%param) };
ok( $@ =~ /marcdb/, "marcdb parametar" );

$param{marcdb} = '/foo/bar/file';

eval { $marc = MARC::Fast->new(%param) };
ok( $@ =~ /foo.bar/, "marcdb exist" );

$param{marcdb} = $marc_file if -e $marc_file;

SKIP: {
	skip "no $param{marcdb} test file ", 37 unless (-e $param{marcdb});

	diag "marc file: $marc_file";

	ok($marc = MARC::Fast->new(%param), "new");

	isa_ok ($marc, 'MARC::Fast');

	#diag Dumper($marc);

	cmp_ok($marc->count, '==', scalar @{$marc->{leader}}, "count == leader");
	cmp_ok($marc->count, '==', scalar @{$marc->{fh_offset}}, "count == fh_offset");

	ok(! $marc->fetch(0), "fetch 0");
	ok(! $marc->last_leader, "no last_leader");
	ok($marc->fetch($marc->count), "fetch max:".$marc->count);
	ok(! $marc->fetch($marc->count + 1), "fetch max+1:".($marc->count+1));

	foreach (1 .. 10) {
		ok($marc->fetch($_), "fetch($_)");

		ok($marc->last_leader, "last_leader $_");

		ok(my $hash = $marc->to_hash($_), "to_hash($_)");
		diag "to_hash($_) = ",Data::Dump::dump($hash) if ($debug);

		ok(my $hash_sf = $marc->to_hash($_, include_subfields => 1), "to_hash($_,include_subfields)");
		diag "to_hash($_, include_subfields => 1) = ",Data::Dump::dump($hash_sf) if ($debug);

		ok(my $ascii = $marc->to_ascii($_), "to_ascii($_)");
		diag "to_ascii($_) ::\n$ascii" if ($debug);
	}

	ok(! $marc->fetch(0), "fetch(0) again");
	ok(! $marc->last_leader, "no last_leader");
}
