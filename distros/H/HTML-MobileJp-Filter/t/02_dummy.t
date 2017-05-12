use strict;
use Test::More tests => 1;

use HTML::MobileJp::Filter;
use HTTP::MobileAgent;
use HTTP::Headers;

my $filter = HTML::MobileJp::Filter->new( filters => [{ module => 'Dummy' }] );
my $html   = $filter->filter(
    mobile_agent => HTTP::MobileAgent->new(
        HTTP::Headers->new(
            'User-Agent' => 'DoCoMo/2.0 P906i(c100;TB;W24H15)',
        )
    ),
    html => "test",
);

is($html, "dummy:{test}");
