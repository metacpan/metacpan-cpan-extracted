#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::TempDir qw(scratch);

use ok 'Directory::Transactional::Stream';
use ok 'Directory::Transactional';

my $s = scratch();

$s->create_tree({
	# new state:
	'foo.txt'        => "les foo",
	'bar.txt'        => "the bar",
	'blah/gorch.txt' => "los gorch",
});

{
	my $m = Directory::Transactional->new(
		root => $s->base,
		auto_commit => 0,
	);

	throws_ok {
		$m->openr("foo.txt");
	} qr/auto commit/i, "can't read files without autocommit";

	throws_ok {
		$m->openw("bar.txt");
	} qr/auto commit/i, "can't write files without autocommit";
}

{
	my $m = Directory::Transactional->new(
		root => $s->base,
	);

	ok( !$m->_txn, "no transaction" );

	{
		my $fh;

		lives_ok { $fh = $m->openr("foo.txt") } "no error opening for reading";

		ok( $m->_txn, "txn still active" );

		throws_ok { $m->txn_begin } qr/auto transaction/, "can't open a new txn if one is already open";

		my $wfh = $m->openw("bar.txt");

		undef $fh;

		$wfh->print("lalala");

		ok( $m->_txn, "txn still active even though live resource changed" );

		$m->rename("foo.txt", "baz.txt");
	}

	ok( !$m->_txn, "no transaction" );

	ok( $s->exists("baz.txt"), "renamed" );

	is( $s->read("bar.txt"), "lalala", "written" );

	{
		my $fh = $m->openw("bar.txt");

		$fh->print("oh noes");

		$m->txn_rollback;
	}

	ok( !$m->_txn, "no transaction" );

	is( $s->read("bar.txt"), "lalala", "file unchanged" );

	ok( $m->exists("bar.txt"), "file exists" );

	is_deeply( [ sort $m->readdir("/") ], [ sort qw(. .. bar.txt baz.txt blah) ], "readdir" );
}

{
	local $SIG{__WARN__} = sub {};
	undef $s; undef $s;
}
