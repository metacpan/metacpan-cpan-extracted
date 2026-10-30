#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(clock_gettime CLOCK_PROCESS_CPUTIME_ID);
use JSON::PP ();
use Unblock::HTTP::Server;
use Unblock::HTTP1::Server;
use Unblock::HTTP1::_Wire;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

# Diagnostic only: identical HTTP1 bytes and canonical messages, with
# deliberately prebuilt response objects to bound constructor cost.
# A cached response is NOT a proposed production policy.
{
    package BenchCostSink;
    sub new ($class) { bless { bytes => 0 }, $class }
    sub unblock_send ($self, $bytes) {
        $self->{bytes} += length($bytes);
        return 1;
    }
    sub unblock_finish ($self) { return }
    sub unblock_abort ($self, $reason) { die $reason }
}

my ($iterations, $rounds, $json) = (15_000, 3, undef);
GetOptions(
    'iterations=i' => \$iterations,
    'rounds=i' => \$rounds,
    'json=s' => \$json,
) or die "invalid options\n";
die "iterations and rounds must be positive\n"
    unless $iterations > 0 && $rounds > 0;

my $wire = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
my $body = 'x' x 32;
my $request = Uniform::HTTP::Request->new(
    method => 'GET', target => '/', version => '1.1',
);
my $template = Uniform::HTTP::Response->new(
    status => 200, body => $body,
);
$template->freeze;

my $direct_sink = BenchCostSink->new;
my $cached_sink = BenchCostSink->new;
my $upper_sink = BenchCostSink->new;
my $upper_cached_sink = BenchCostSink->new;
my $direct = Unblock::HTTP1::Server->new(
    transport => $direct_sink,
    receive_body => 'buffered',
    max_buffered_body_bytes => 1_048_576,
    on_request => sub { return },
    on_request_end => sub ($tx, $req) {
        $tx->respond(status => 200, body => $body);
    },
);
my $direct_cached = Unblock::HTTP1::Server->new(
    transport => $cached_sink,
    receive_body => 'buffered',
    max_buffered_body_bytes => 1_048_576,
    on_request => sub { return },
    on_request_end => sub ($tx, $req) {
        $tx->respond($template);
    },
);
my $upper = Unblock::HTTP::Server->new(
    http1 => {},
    on_request => sub ($tx, $req) {
        $tx->respond(status => 200, body => $body);
    },
)->attach_stream(transport => $upper_sink);
my $upper_cached = Unblock::HTTP::Server->new(
    http1 => {},
    on_request => sub ($tx, $req) {
        $tx->respond($template);
    },
)->attach_stream(transport => $upper_cached_sink);

my @cases = (
    [ 'uniform_constructor', sub {
        Uniform::HTTP::Response->new(status => 200, body => $body);
    } ],
    [ 'uniform_constructor_plus_plan', sub {
        Unblock::HTTP1::_Wire::response_plan(
            $request, Uniform::HTTP::Response->new(
                status => 200, body => $body,
            ),
        );
    } ],
    [ 'wire_plan_prebuilt_canonical', sub {
        Unblock::HTTP1::_Wire::response_plan($request, $template);
    } ],
    [ 'direct_engine_fresh', sub { $direct->input($wire) } ],
    [ 'direct_engine_prebuilt', sub { $direct_cached->input($wire) } ],
    [ 'facade_engine_fresh', sub { $upper->input($wire) } ],
    [ 'facade_engine_prebuilt', sub { $upper_cached->input($wire) } ],
);

my @rows;
for my $round (1 .. $rounds) {
    # Rotate the case order to avoid favoring one CPU warmup position.
    for my $offset (0 .. $#cases) {
        my ($name, $run) = @{ $cases[($offset + $round - 1) % @cases] };
        $run->() for 1 .. 300;
        my $start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
        $run->() for 1 .. $iterations;
        my $cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $start;
        my $us = $cpu * 1_000_000 / $iterations;
        push @rows, {
            case => $name, round => $round,
            iterations => $iterations, cpu_us_per_iteration => $us,
        };
        printf "round=%d %-36s %8.3f CPU us/iteration\n",
            $round, $name, $us;
    }
}
for my $entry (
    [ $direct_sink, 'direct fresh' ],
    [ $cached_sink, 'direct prebuilt' ],
    [ $upper_sink, 'facade fresh' ],
    [ $upper_cached_sink, 'facade prebuilt' ],
) {
    my ($sink, $label) = @$entry;
    die "no serialized bytes for $label\n" unless $sink->{bytes} > 0;
}
die "the prebuilt canonical Response was mutated\n"
    if $template->is_mutable || !$template->has_buffered_body
    || $template->body ne $body || $template->status != 200;

if ($json) {
    open my $fh, '>', $json or die "$json: $!";
    print {$fh} JSON::PP->new->canonical->pretty->encode(\@rows);
    close $fh or die $!;
}
