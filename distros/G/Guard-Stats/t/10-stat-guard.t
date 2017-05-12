#!/usr/bin/perl -w

use strict;
use Test::More tests => 24;
use Test::Exception;
use Data::Dumper;
use Time::HiRes qw(sleep);

use Guard::Stats;

my $G = Guard::Stats->new( );
lives_ok {
	$G->get_stat;
} "get_stat() is OK on empty guard";

my $pos = 0;
my $neg = 0;
is ($G->on_level(2, sub {not "POS"; $pos++}), $G, "on_level return self");
$G->on_level(-1, sub {note "NEG"; $neg++});

is ($pos, 0, "on_level(2) not called");
my $g = $G->guard;

is ($pos, 0, "on_level(2) still not called");
my $g2 = $G->guard;
is ($pos, 1, "on_level(2) called once");
is ($neg, 0, "on_level(-1) not called yet");

# sleep 0.001;
ok (!$g->is_done, "is_done = 0");
$g->end;
ok ($g->is_done, "is_done = 1");

note Dumper($G->get_stat);
nonnegative($G->get_stat);

is ($G->alive, 2, "2 items alive");
is ($G->done, 1, "1 done");

is ($neg, 1, "on_level(-1) called once");

is ($G->zombie, 1, "1 zombie");
undef $g;
is ($G->zombie, 0, "1 zombie gone");

# note Dumper($G->get_time_stat);
nonnegative($G->get_stat);
is ($G->alive, 1, "1 item alive");
is ($neg, 1, "on_level(-1) called once");

undef $g2;
# note Dumper($G->get_time_stat);
is ($G->alive, 0, "none alive");
is ($G->done, 1, "1 done (still)");
is ($neg, 1, "on_level(-1) called once");

note Dumper($G->get_stat);
nonnegative($G->get_stat);

my $results = $G->get_stat_result;
is (ref $results, 'HASH', "Fetched results");
is_deeply($results, { ""=>1 }, "results as expected");

is ($G->dead, $G->total, "All instances are dead");

sub nonnegative {
	my $hash = shift;
	my $msg = shift || "No negative keys in hash";
	my @neg = grep { $hash->{$_} < 0 } keys %$hash;
	is (scalar @neg, 0, $msg)
		or diag explain $hash;
};
