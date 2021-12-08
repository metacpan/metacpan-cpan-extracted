use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../t/lib";
use lib "$Bin/../lib";

#use Test::More;
use XML::LibXML;
use TestUtils qw(slurp);
use Benchmark;

=pod

Using XPATH expressions is faster than getElementsBy*, especially for filtering.
Here is the output on my computer

    Benchmark: timing 200000 iterations of DOM, XPATH...
           DOM:  8 wallclock secs ( 7.89 usr +  0.00 sys =  7.89 CPU) @ 25348.54/s (n=200000)
         XPATH:  6 wallclock secs ( 5.78 usr +  0.00 sys =  5.78 CPU) @ 34602.08/s (n=200000)
    Benchmark: timing 200000 iterations of DOM2, XPATH2...
          DOM2:  7 wallclock secs ( 6.77 usr +  0.00 sys =  6.77 CPU) @ 29542.10/s (n=200000)
        XPATH2:  5 wallclock secs ( 4.98 usr +  0.00 sys =  4.98 CPU) @ 40160.64/s (n=200000)

Below is the benchmark.

=cut

my $dom = XML::LibXML->load_html(
    string            => \(slurp("$Bin/../t/data/collectOpenGraph.html")),
    recover           => 2,
    suppress_errors   => 1,
    suppress_warnings => 1,
    no_network        => 1,
    no_xinclude_nodes => 1,
);
my $doc = $dom->documentElement;

timethese(
    200000,
    {
        'DOM' => sub {
            map { $_->hasAttribute('property') ? $_ : () } $doc->getElementsByTagName('meta');
        },
        'XPATH' => sub { $doc->findnodes('//meta[@property]'); },
    }
);


timethese(
    200000,
    {
        'DOM2' => sub {
            $doc->getElementsByTagName('meta');
        },
        'XPATH2' => sub { $doc->findnodes('//meta'); },
    }
);

# done_testing;
