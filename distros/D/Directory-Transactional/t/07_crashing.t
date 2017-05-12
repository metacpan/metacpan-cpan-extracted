#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use File::Spec::Functions;

use constant FORKS => 20;
use constant TIME  => 10; # how many seconds to test for

BEGIN {
	if ( File::Spec->isa("File::Spec::Unix") ) {
		plan tests => 3 + TIME;
	} else {
		plan skip_all => "not running on something UNIXish";
	}
}

use Test::TempDir qw(scratch);

use ok 'Directory::Transactional';


my $s = scratch();

$s->create_tree({
	'account_1.txt' => "0",
	'account_2.txt' => "0",
	'account_3.txt' => "0",
});

my @pids;

sub spawn {
	my $pid = fork;

	unless ( defined $pid ) {
		# probably a resource availability problem
		# wait a while and try again
		select( undef, undef, undef, 0.1 );
		return;
	}

	if ( $pid ) {
		push @pids, $pid;
	} else {
		srand($$); # otherwise rand returns the same in all children

		alarm 5;
		my $d = Directory::Transactional->new(
			global_lock => ( rand(1) < 0.5 ),
			root        => $s->base,
		);
		alarm 0;

		while ( 1 ) {
			eval {
				$d->txn_do(sub {
					# test for atomicity by modifying two files together in a dependent way

					my @accounts = ( 1 .. 3 );
					splice(@accounts, int(rand 3), 1); # remove one at random

					$d->lock_path_write("account_${_}.txt") for @accounts;

					my @balances = map { scalar readline $d->openr("account_${_}.txt") } @accounts;

					my $diff = ( int(rand 1000) - 500 );

					$balances[0] += $diff;
					$balances[1] -= $diff;

					$d->openw("account_${_}.txt")->print( shift @balances ) for @accounts;
				});
			};

			if ( $@ ) {
				use POSIX qw(_exit);
				_exit(0);
			}
		}
	}
}

my $checks = 0;

sub check_state {
	eval {
		alarm 5;
		my $d = Directory::Transactional->new( root => $s->base ); # this may die if there is a crashed txn and multiple other dirs are still live
		alarm 0;

		$d->txn_do(sub {
			# avoid deadlocks by locking for writing
			$d->lock_path_write("account_${_}.txt") for 1 .. 3;
			my $one   = readline $d->openr("account_1.txt");
			my $two   = readline $d->openr("account_2.txt");
			my $three = readline $d->openr("account_3.txt");

			chomp for $one, $two, $three;

			$checks++;
			is( $one + $two + $three, 0, "accounts are balanced ($one, $two, $three)" );
		});
	}
}

my $t = time + TIME;

my $last = time;

do {
	if ( @pids <= 1 ) {
		while ( time < $t and @pids < FORKS ) {
			spawn();
		}
	}

	select(undef, undef, undef, 0.01) if rand() < 0.5;

	my $kid = splice(@pids, int(rand @pids), 1);
	kill 9, $kid;
	waitpid $kid, 0;

	if ( time > $last and $checks < TIME ) {
		check_state();
		$last = time;
	}
} while ( @pids );

if ( $checks < TIME ) {
	SKIP: { skip "failed to obtain exclusive recovery lock", TIME - $checks; };
}

check_state();
ok( !$@, "no error in final check" );

{
	local $SIG{__WARN__} = sub { }; # make Directory::Scratch shut up
	undef $s; undef $s;
}
