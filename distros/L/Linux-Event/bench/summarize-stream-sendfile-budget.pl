#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use JSON::PP qw(decode_json);

sub median (@numbers) {
    return undef unless @numbers;
    @numbers = sort { $a <=> $b } @numbers;
    my $middle = int(@numbers / 2);
    return @numbers % 2 ? $numbers[$middle]
        : ($numbers[$middle - 1] + $numbers[$middle]) / 2;
}

@ARGV or die "usage: $0 budget-*.jsonl\n";
my %cases;
for my $path (@ARGV) {
    open my $file, '<', $path or die "open $path: $!";
    while (my $line = <$file>) {
        my $entry = decode_json($line);
        die "$path: unverified transfer\n" unless $entry->{verified};
        my $budget = $entry->{budget_bytes};
        my $size = $entry->{bytes};
        my $mode = $entry->{mode};
        die "$path: missing experiment labels\n"
            unless $budget && $size && $mode;
        push @{ $cases{$budget}{$size}{$mode} }, $entry;
    }
}

my ($baseline_budget) = sort { $a <=> $b } keys %cases;
for my $size (sort { $a <=> $b } keys %{ $cases{$baseline_budget} }) {
    printf "\n%s MiB verified Stream transfers (1-ms timer)\n", $size / 1048576;
    printf "%9s %-10s %6s %12s %14s %14s %13s\n",
        'budget', 'mode', 'trials', 'CPU ms/MiB', 'throughput MiB/s',
        'tick p95 ms', 'tick max ms';
    for my $budget (sort { $a <=> $b } keys %cases) {
        for my $mode (qw(sendfile copy preloaded)) {
            my $items = $cases{$budget}{$size}{$mode} // [];
            next unless @$items;
            my $cpu = median(map { $_->{sender_cpu_ms_per_mib} } @$items);
            my $rate = median(map { $_->{throughput_mib_s} } @$items);
            my $p95 = median(map {
                defined $_->{timer_late_p95_ms}
                    ? $_->{timer_late_p95_ms} : ()
            } @$items);
            my $maximum = median(map {
                defined $_->{timer_late_max_ms}
                    ? $_->{timer_late_max_ms} : ()
            } @$items);
            printf "%9d %-10s %6d %12.4f %14.2f %14s %13s\n",
                $budget, $mode, scalar(@$items), $cpu, $rate,
                defined($p95) ? sprintf('%.4f', $p95) : '-',
                defined($maximum) ? sprintf('%.4f', $maximum) : '-';
        }
    }
}
