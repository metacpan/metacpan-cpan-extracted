#!/usr/bin/perl
use 5.020; use strict; use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON ();
use Mail::DKIM2::Validate;

binmode STDIN; binmode STDOUT;
my $MAX = 256 * 1024;
# Production validates against LIVE DNS (like the milter and any real-world
# verifier), so a broken/truncated key record is surfaced, not masked. The
# dns.json override is available ONLY for offline testing via the
# DKIM2_DNS_JSON env var, and is deliberately NOT defaulted here.
my $dns_path = $ENV{DKIM2_DNS_JSON};

my $len = $ENV{CONTENT_LENGTH} // 0;
my $body = '';
if ($len) {
    if ($len > $MAX) {
        print "Status: 413 Payload Too Large\r\nContent-Type: application/json\r\n\r\n";
        print JSON::encode_json({ overall => 'fail', summary => 'message too large (max 256 KB)', levels => [] });
        exit 0;
    }
    read(STDIN, $body, $len);
} else {
    local $/; $body = <STDIN> // '';
}

my $rep = eval { Mail::DKIM2::Validate::report($body, DnsPath => $dns_path) };
if (my $err = $@) {
    $rep = { overall => 'fail', summary => "internal error: $err", counts => {}, levels => [] };
}

my $json = JSON->new->canonical(1)->encode($rep);
print "Status: 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\n\r\n";
print $json;
exit 0;
