package Gearman::Starter::Util;
use strict;
use warnings;

sub display_scoreboard {
    my $scoreboard = shift;
    my $stats = $scoreboard->read_all;
    my $raw_stats;
    my $busy = 0;
    my $idle = 0;
    for my $pid ( sort { $a <=> $b } keys %$stats) {
        if ( $stats->{$pid} =~ m!^A! ) {
            $busy++;
        }
        else {
            $idle++;
        }
        $raw_stats .= sprintf "%-14d %s\n", $pid, $stats->{$pid}
    }
    $raw_stats = <<"EOF";
BusyWorkers: $busy
IdleWorkers: $idle
--
pid       Status Counter Comment
$raw_stats
EOF
    $raw_stats;
}

1;
