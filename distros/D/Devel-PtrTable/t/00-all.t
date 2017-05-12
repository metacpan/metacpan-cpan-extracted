#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    use Config;
    if(! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use threads;
use Devel::PtrTable;
use Test::More;

my $ref = \"Scalar";
my $oldaddr = $ref + 0;

my $thr = threads->create(
	sub {
		my $refcopy = PtrTable_get($oldaddr);
		diag $$refcopy, $$ref;
		my $ret = {};
		if(
			$refcopy && 
			$refcopy == $ref && 
			$$refcopy eq $$ref)
		{
			$ret->{Fetch} = 1;
		}

		PtrTable_freecopied();
		diag "Warning message is OK";
		my $should_be_empty = PtrTable_get($oldaddr);
		if(!$should_be_empty) {
			$ret->{Free} = 1;
		}
		return $ret;
	}
);

my $ret = $thr->join();
ok($ret->{Fetch}, "Got expected refaddr");
ok($ret->{Free}, "Freed");
done_testing();
