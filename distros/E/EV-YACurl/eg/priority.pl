#!/usr/bin/env perl
# Place a client's transfers in EV's priority order. libcurl runs every
# callback from inside the watchers the client owns, so a client at MINPRI
# yields to the latency-sensitive timer below it.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';

my @urls = @ARGV ? @ARGV : map { "https://www.perl.org$_" } qw(/ /get.html /docs/ /books/);

my $bulk = EV::YACurl->new({});
$bulk->priority(EV::MINPRI);          # yield to everything else in the loop

my $ticks = 0;
my $tick = EV::timer(0, 0.05, sub { $ticks++ });
$tick->priority(EV::MAXPRI);          # this must stay responsive

my $done = 0;
for my $url (@urls) {
    my $bytes = 0;
    $bulk->request(sub {
        my ($response, $error) = @_;
        $done++;
        printf "%-40s %s\n", $url,
            $error ? "failed: $error"
                   : sprintf('%d, %d bytes', $response->getinfo(CURLINFO_RESPONSE_CODE), $bytes);

        # The repeating timer keeps the loop alive for good, so EV::run would
        # never return on its own: break out once the last transfer lands.
        EV::break if $done == @urls;
    }, {
        CURLOPT_URL => $url,
        CURLOPT_FOLLOWLOCATION => 1,
        CURLOPT_WRITEFUNCTION => sub { $bytes += length $_[0] },
    });
}

EV::run;
$tick->stop;

printf "\nthe high priority timer ticked %d times while %d transfers ran\n",
    $ticks, scalar @urls;
printf "bulk client priority is %d (EV::MINPRI is %d)\n", $bulk->priority, EV::MINPRI;
