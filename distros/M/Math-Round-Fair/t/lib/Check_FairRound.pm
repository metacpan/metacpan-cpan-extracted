use strict;
package Check_FairRound;

my $verify_stats;
BEGIN {
	$verify_stats = 1;
        eval "use Math::CDF qw/pbinom/";
        if($@) {
                # This probably means that Math::CDF was not installed because
                # it was needed only for running this tests, and the user
                # elected not to do so.
		$verify_stats = 0;
		warn "Not checking statistical properties because Math::CDF " .
		  "could not be loaded: $@";
        }
}

use Math::Round::Fair qw(round_adjacent);

sub run_case {
	my ($in, $iterations, $how_unlikely) = @_;
	die "Total loss of precision" if 1.0 - $how_unlikely/4.0 == 1.0;
	my @in = @$in;

	my $sum=0.0;
	$sum += $_ for(@in);

	my @accums = map { 0.0 } (@in, 'SUM');
	for my $iteration (1..$iterations) {
		eval {
			my @out = round_adjacent(@in);
			die "wrong number of results" unless @out==@in;
			my $round_sum=0;
			$round_sum += $_ for(@out);

			for(
			  (map { [$in[$_], $out[$_]] } ($[..$#in)),
			  [$sum, $round_sum]
			) {
				my ($in, $out) = @$_;
				if($out == int($out)) {
					next if abs($out - $in) < 1.0;
				}
				die "$in rounded to $out";
			}

			for($[..$#in) {
				$accums[$_] += $out[$_];
			}
			$accums[-1] += $round_sum;
		};
		chomp($@) and die "$@ on iteration number $iteration" if $@;
	}

	if($verify_stats) {
		# Check that each average meets its expectation.
		my @avgs = map { $_/$iterations } @accums;
		for(
		  (map { [$in[$_], $avgs[$_]] } ($[..$#in)), [$sum, $avgs[-1]]
		) {
			my ($expect, $average) = @$_;
			my $n = $iterations;
			my $base = int($expect);
			my $p = abs($expect - $base);

			my $x = int($n * abs($average - $base) + 0.5);
			my $prob = pbinom($x, $n, $p);
			$prob = 1.0 - pbinom($x-1, $n, $p) if $x && $prob > 0.5;
			if($prob < $how_unlikely) {
				die
 "$expect rounded on average to $average (almost certainly a bug - prob=$prob)";
			}
		}
	}
}

1;

