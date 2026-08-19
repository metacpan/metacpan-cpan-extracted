#!/usr/bin/env perl
# Graceful shutdown: a SIGINT watcher stops feeding the queue and lets the
# transfers already in flight finish before the loop returns. Ctrl-C is what
# does it in real life; here a timer raises the signal so the example ends.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';

my $limit = 3;
my @queue = @ARGV ? @ARGV : map { "https://www.perl.org$_" } qw(
    / /get.html /docs/ /books/ /about.html /events.html /media.html /learn.html
);
my $queued = @queue;

my $client = EV::YACurl->new({});
my ($running, $stopping, $finished, @failed) = (0, 0, 0);

my $pump;
$pump = sub {
    while (!$stopping && $running < $limit && @queue) {
        my $url = shift @queue;
        my $bytes = 0;
        $running++;

        $client->request(sub {
            my ($response, $error) = @_;
            $running--;
            $finished++;

            push @failed, "$url: $error" if $error;
            printf "  %-40s %s\n", $url,
                $error ? 'failed' : $response->getinfo(CURLINFO_RESPONSE_CODE) . ", $bytes bytes";

            $pump->();
        }, {
            CURLOPT_URL => $url,
            CURLOPT_FOLLOWLOCATION => 1,
            CURLOPT_WRITEFUNCTION => sub { $bytes += length $_[0] },
        });
    }

    # A signal watcher keeps the loop alive by itself, so it has to be broken.
    EV::break if !$running && ($stopping || !@queue);
};

my $sigint = EV::signal INT => sub {
    return if $stopping;
    $stopping = 1;
    printf "SIGINT: draining %d transfer(s), dropping %d queued\n", $running, scalar @queue;
    EV::break unless $running;
};

my $ctrl_c = EV::timer(0.3, 0, sub { kill 'INT', $$ });

$pump->();
EV::run;

printf "%d of %d finished, %d never started\n", $finished, $queued, scalar @queue;
warn "$_\n" for @failed;
