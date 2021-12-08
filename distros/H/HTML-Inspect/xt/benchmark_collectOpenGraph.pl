use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../t/lib";
use lib "$Bin/../lib";
use HTML::Inspect;
use TestUtils qw(slurp);
use Benchmark qw(timethis timethese);

=pod

Optimising collectOpenGraph().
Running a benchmark for 3 seconds. higher number of calls is better.
Here is the output on my computer.

1. Initial state
Higher values than 3617.11/s (n=10996) is better
    timethis for 3:  3 wallclock secs ( 2.94 usr +  0.10 sys =  3.04 CPU) @ 3617.11/s (n=10996)

Below is the benchmark.

2. With precompiled XPATH queries. Not much faster than hardcodded arguments

    Benchmark: timing 400000 iterations of HARD_XPATH, PRECOMPILED_XPATH, RAW_XPATH...
    HARD_XPATH: 20 wallclock secs (20.05 usr +  0.01 sys = 20.06 CPU) @ 19940.18/s (n=400000)
    PRECOMPILED_XPATH: 19 wallclock secs (19.14 usr +  0.01 sys = 19.15 CPU) @ 20887.73/s (n=400000)
     RAW_XPATH: 20 wallclock secs (20.10 usr +  0.00 sys = 20.10 CPU) @ 19900.50/s (n=400000)
=cut

my $html = slurp("$Bin/../t/data/open-graph-protocol-examples/video-movie.html");
timethis(
    -3,
    sub {
        HTML::Inspect->new(location => 'http://example.com/doc', html_ref => \$html)->collectOpenGraph();

    }
);
my $x_pref          = '//html[@prefix] | head[@prefix]';
my $X_PREFIXES      = XML::LibXML::XPathExpression->new($x_pref);
my $x_m_p           = '//meta[@property]';
my $X_META_PROPERTY = XML::LibXML::XPathExpression->new($x_m_p);

my $doc = XML::LibXML->load_html(
    string            => \$html,
    recover           => 2,
    suppress_errors   => 1,
    suppress_warnings => 1,
    no_network        => 1,
    no_xinclude_nodes => 1,
)->documentElement;
my $xpc = XML::LibXML::XPathContext->new($doc);
timethese(
    400_000,
    {
        PRECOMPILED_XPATHC => sub { $xpc->findnodes($X_PREFIXES);                       $xpc->findnodes($X_META_PROPERTY) },
        VAR_XPATHC         => sub { $xpc->findnodes($x_pref);                           $xpc->findnodes($x_m_p) },
        LITERAL_XPATC      => sub { $xpc->findnodes('//html[@prefix] | head[@prefix]'); $xpc->findnodes($x_m_p) },
        PRECOMPILED_NODE   => sub { $doc->findnodes($X_PREFIXES);                       $doc->findnodes($X_META_PROPERTY) },
        VAR_NODE           => sub { $doc->findnodes($x_pref);                           $doc->findnodes($x_m_p) },
        LITERAL_NODE       => sub { $doc->findnodes('//html[@prefix] | head[@prefix]'); $doc->findnodes($x_m_p) },
    },
);

