#!/usr/bin/env perl
# Stream a URL to a file without holding it in memory, printing progress as it
# goes. A die() inside a callback is caught and turned into a warning, so
# failures are reported after the loop rather than from inside it.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';

my $url  = shift or die "usage: $0 URL [FILE]\n";
my $path = shift || 'download.out';

open my $out, '>:raw', $path or die "$path: $!\n";

my $client = EV::YACurl->new({});
my ($written, $expected, $done, $failed) = (0, 0, 0, undef);

$client->request(sub {
    my ($response, $error) = @_;
    $done = 1;

    if ($error) {
        $failed = $error;
        return;
    }

    printf "\r%s -> %s (%d bytes, %.1f KB/s)\n", $url, $path, $written,
        $response->getinfo(CURLINFO_SPEED_DOWNLOAD_T) / 1024;
}, {
    CURLOPT_URL => $url,
    CURLOPT_FOLLOWLOCATION => 1,
    CURLOPT_HEADERFUNCTION => sub {
        $expected = $1 if $_[0] =~ /^content-length:\s*(\d+)/i;
    },
    CURLOPT_WRITEFUNCTION => sub {
        print { $out } $_[0];
        $written += length $_[0];
        printf "\r%s %d bytes",
            $expected ? sprintf('%3d%%', 100 * $written / $expected) : '    ',
            $written;
    },
});

EV::run until $done;
close $out;

if ($failed) {
    unlink $path;
    die "\n$url: $failed\n";
}
