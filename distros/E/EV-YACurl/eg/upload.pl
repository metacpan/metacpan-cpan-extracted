#!/usr/bin/env perl
# Upload a file with a read callback. Returning the empty string ends the
# transfer; returning undef aborts it, which is how you cancel an upload from
# inside the loop.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';

my $url  = shift or die "usage: $0 URL FILE\n";
my $path = shift or die "usage: $0 URL FILE\n";

open my $in, '<:raw', $path or die "$path: $!\n";
my $size = -s $in;

my $client = EV::YACurl->new({});
my ($sent, $body, $done, $failed) = (0, '', 0, undef);

$client->request(sub {
    my ($response, $error) = @_;
    $done = 1;

    if ($error) {
        $failed = $error;
        return;
    }

    printf "uploaded %d of %d bytes, server said %d\n%s",
        $sent, $size, $response->getinfo(CURLINFO_RESPONSE_CODE), $body;
}, {
    CURLOPT_URL => $url,
    CURLOPT_UPLOAD => 1,
    CURLOPT_INFILESIZE_LARGE => $size,
    CURLOPT_READFUNCTION => sub {
        my ($wanted) = @_;
        my $chunk = '';
        my $got = read $in, $chunk, $wanted;
        return undef unless defined $got;   # read error: abort the transfer
        $sent += $got;
        return $chunk;                      # '' at EOF ends it cleanly
    },
    CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
});

EV::run until $done;
close $in;
die "$url: $failed\n" if $failed;
