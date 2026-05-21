#!/usr/bin/env perl
# Adapt EV::cares callbacks to Future objects, no extra modules required.
# Run the EV loop until the wait_all Future is ready.
# Usage: perl eg/futures.pl [host ...]
use strict;
use warnings;
use EV;
use Future;
use EV::cares qw(:status);

sub resolve_f {
    my ($r, $name) = @_;
    my $f = Future->new;
    $r->resolve($name, sub {
        my ($status, @addrs) = @_;
        $status == ARES_SUCCESS
            ? $f->done(@addrs)
            : $f->fail(EV::cares::strerror($status), 'EV::cares', $status);
    });
    return $f;
}

my @names = @ARGV ? @ARGV : qw(
    google.com cloudflare.com github.com amazon.com perl.org
);

my $r = EV::cares->new(timeout => 5, tries => 2);

my @pairs = map [$_, resolve_f($r, $_)], @names;
my $all   = Future->wait_all(map $_->[1], @pairs);

EV::run until $all->is_ready;

for my $pair (@pairs) {
    my ($name, $f) = @$pair;
    if ($f->is_done) {
        printf "%-25s -> %s\n", $name, join(', ', $f->result);
    } else {
        my ($msg) = $f->failure;
        printf "%-25s -> FAIL %s\n", $name, $msg;
    }
}
