use v5.36;
use strict;
use warnings;

use Benchmark qw(cmpthese);
use Getopt::Long qw(GetOptions);
use Linux::Event::HTTP::_HTTP1;

my $seconds = 1;
my $iterations;
GetOptions(
    'seconds=i'    => \$seconds,
    'iterations=i' => \$iterations,
) or die "usage: $0 [--seconds=N | --iterations=N]\n";

die "--seconds must be positive\n" if $seconds < 1;
die "--iterations must be positive\n"
    if defined($iterations) && $iterations < 1;

my $count = defined($iterations) ? $iterations : -$seconds;
my $parser = 'Linux::Event::HTTP::_HTTP1';
my $sink = 0;

say "picohttpparser ", $parser->pico_version;
say defined($iterations) ? "iterations=$iterations" : "seconds=$seconds per case";

for my $header_count (4, 16, 64) {
    my @lines = (
        "GET /api/resource?x=1 HTTP/1.1\r\n",
        "Host: example.test\r\n",
        "User-Agent: Linux-Event-HTTP-Bench\r\n",
        "Accept: */*\r\n",
        "Connection: keep-alive\r\n",
    );

    for my $i (5 .. $header_count) {
        push @lines, "X-Bench-$i: value-$i\r\n";
    }
    push @lines, "\r\n";

    my $request = join '', @lines;

    say '';
    say "headers=$header_count bytes=", length($request);

    cmpthese(
        $count,
        {
            pico_probe => sub {
                $sink += $parser->probe_request($request, 0, 100);
            },
            pico_offsets => sub {
                my $parsed = $parser->parse_request_offsets($request, 0, 100);
                $sink += $parsed->[0];
            },
            native_state => sub {
                my $native = $parser->parse_request($request, 0, 100);
                $sink += $native->_consumed;
            },
            native_common_access => sub {
                my $native = $parser->parse_request($request, 0, 100);
                $sink += length $native->method;
                $sink += length $native->target;
                $sink += length($native->header('Host') // '');
            },
            pico_materialize_all => sub {
                my $parsed = $parser->parse_request_offsets($request, 0, 100);
                $sink += length substr($request, $parsed->[2], $parsed->[3]);
                $sink += length substr($request, $parsed->[4], $parsed->[5]);
                for my $header (@{$parsed->[6]}) {
                    $sink += length substr($request, $header->[0], $header->[1]);
                    $sink += length substr($request, $header->[2], $header->[3]);
                }
            },
        },
    );
}

# Keep the benchmarked work observable without cluttering normal output.
END { $sink = 0 if $sink < 0 }
