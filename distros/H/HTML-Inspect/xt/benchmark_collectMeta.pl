use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../t/lib";
use lib "$Bin/../lib";
use HTML::Inspect;
use TestUtils qw(slurp);
use Benchmark qw(timethis);

=pod

Optimising collectMeta().
Running a benchmark for 3 seconds. higher number of calls is better.
Here is the output on my computer.

1. Initial state
Higher values than 4095.98/s (n=13230) is(will be) better:
    timethis for 3:  4 wallclock secs ( 3.23 usr +  0.00 sys =  3.23 CPU) @ 4095.98/s (n=13230)

Below is the benchmark.

=cut

timethis(
    -3,
    sub {
        my $html = slurp("$Bin/../t/data/collectMeta.html");
        HTML::Inspect->new(location => 'http://example.com/doc', html_ref => \$html)->collectMeta;

    }
);


