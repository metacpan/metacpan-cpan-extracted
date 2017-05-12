#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

SKIP: {

    if ( !$ENV{TEST_SPIDER} ) {
        diag "set TEST_SPIDER env var to test the spider";
        skip "set TEST_SPIDER env var to test the spider", 2;
    }

    eval "use Dezi::Aggregator::Spider";
    if ( $@ && $@ =~ m/([\w:]+)/ ) {
        skip "$1 required for spider test: $@", 3;
    }

    ok( my $spider = Dezi::Aggregator::Spider->new(
            verbose   => $ENV{DEZI_DEBUG},
            max_depth => 2,
            delay     => 1,
            filter    => sub { diag( "doc filter on " . $_[0]->url ) },
        ),
        "new spider"
    );

    diag("spidering swish-e.org/docs");
    is( $spider->crawl('http://www.swish-e.org/docs/'), 26, "crawl" );

}
