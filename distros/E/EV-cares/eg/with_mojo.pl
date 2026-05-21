#!/usr/bin/env perl
# Use EV::cares for resolution alongside Mojo::UserAgent.
# Mojo::IOLoop uses EV when EV is loaded first.
# Usage: perl eg/with_mojo.pl https://example.com/ ...
use strict;
use warnings;
use EV;
use Mojo::URL;
use Mojo::UserAgent;
use EV::cares qw(:status);

my @urls = @ARGV ? @ARGV : qw(
    https://example.com/
    https://www.cloudflare.com/
    https://github.com/
);

my $r  = EV::cares->new(timeout => 5);
my $ua = Mojo::UserAgent->new->max_redirects(2);

my $pending = 0;

for my $url (@urls) {
    my $host = Mojo::URL->new($url)->host or next;

    $pending++;
    $r->resolve($host, sub {
        my ($status, @addrs) = @_;
        printf "DNS  %-25s %s\n", $host,
            $status == ARES_SUCCESS ? join(', ', grep defined, @addrs[0..1]) : 'FAIL';

        if ($status != ARES_SUCCESS) {
            EV::break unless --$pending;
            return;
        }
        $pending++;
        $ua->head($url => sub {
            my (undef, $tx) = @_;
            my $code = $tx->res->code // 'no-response';
            printf "HEAD %-25s %s\n", $host, $code;
            EV::break unless --$pending;
        });
        EV::break unless --$pending;
    });
}

EV::run;
