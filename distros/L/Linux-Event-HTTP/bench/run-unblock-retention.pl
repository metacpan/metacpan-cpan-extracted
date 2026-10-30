#!/usr/bin/env perl
use v5.36;
use Getopt::Long qw(GetOptions);
use JSON::PP;
use Time::HiRes qw(clock_gettime CLOCK_PROCESS_CPUTIME_ID);
use Unblock::HTTP1::Server;
use Unblock::HTTP1::Client;

# Linux-only, socket-free retained-Transaction diagnostic. Each invocation
# measures one role in a fresh process. RSS includes allocator overhead;
# it is not a socket throughput or peak-memory measurement.
package RetentionSink;
sub unblock_send ($self, $bytes) { $self->{bytes} += length($bytes); 1 }
sub unblock_finish { }
sub unblock_abort { die $_[1] }
package main;
my ($requests, $body_bytes, $role, $label, $json) = (256, 262144, 'server', '', undef);
GetOptions('requests=i' => \$requests, 'body-bytes=i' => \$body_bytes,
    'role=s' => \$role, 'label=s' => \$label, 'json=s' => \$json) or die 'bad options';
die 'requests must be positive' unless $requests > 0;
die 'body-bytes must be at least 16' unless $body_bytes >= 16;
die 'role must be server or client' unless $role =~ /\A(?:server|client)\z/;
sub rss_kib {
    open my $fh, '<', '/proc/self/status' or die $!;
    while (<$fh>) { return 0 + $1 if /^VmRSS:\s+(\d+) kB/ }
    die 'VmRSS missing';
}
my $sink = bless { bytes => 0 }, 'RetentionSink';
my @retained;
my $serial = 0;
sub body { sprintf('%016d', ++$serial) . ('x' x ($body_bytes - 16)) }
my $engine = $role eq 'server'
    ? Unblock::HTTP1::Server->new(transport => $sink, on_request => sub ($tx, $request) {
        $tx->respond(status => 200, body => body());
        push @retained, $tx;
    })
    : Unblock::HTTP1::Client->new(transport => $sink);
my $rss_before = rss_kib();
my $start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
for (1 .. $requests) {
    if ($role eq 'server') {
        $engine->input("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
    } else {
        push @retained, $engine->request(method => 'POST', target => '/',
            headers => [['Host', 'localhost']], body => body());
        $engine->input("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n");
    }
}
my $cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $start;
my $rss_after = rss_kib();
for my $i (0 .. $#retained) {
    my $tx = $retained[$i];
    die 'incomplete transaction' unless $tx->is_complete;
    my $message = $role eq 'server' ? $tx->response : $tx->request;
    die 'canonical body was lost or changed'
        unless length($message->body) == $body_bytes
            && substr($message->body, 0, 16) eq sprintf('%016d', $i + 1);
}
my $row = { role => $role, label => $label, requests => $requests,
    body_bytes => $body_bytes, canonical_body_bytes => $requests * $body_bytes,
    rss_before_kib => $rss_before, rss_after_kib => $rss_after,
    retained_rss_delta_kib => $rss_after - $rss_before,
    cpu_us_per_request => $cpu * 1_000_000 / $requests,
    bytes_sent => $sink->{bytes}, perl => "$^V",
    engine_source => $INC{'Unblock/HTTP1/_Engine.pm'} };
my $encoded = JSON::PP->new->canonical->pretty->encode($row);
print $encoded;
if ($json) {
    open my $fh, '>', $json or die "$json: $!";
    print {$fh} $encoded;
    close $fh or die $!;
}
