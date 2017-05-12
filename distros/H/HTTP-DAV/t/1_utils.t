#!/usr/local/bin/perl -w
use strict;
use HTTP::DAV;
use Test;

# Tests the DAV::Utils functions

my $TESTS;
BEGIN {
    $TESTS=6;
    plan tests => $TESTS;
}


#HTTP::DAV::DebugLevel(3);

#ok($response->get_responsedescription(), 'There has been an access violation error.');

# Test get_leafname
my @splits = (
 ["http://server.com/",               "http://server.com",      ""           ],
 ["http://server.com",                "http://server.com" ,     ""           ],
 ["http://server.com/index.html",     "http://server.com",      "index.html" ],
 ["http://server.com/test/index.html","http://server.com/test", "index.html" ],
 ["http://server.com/test/test2/",    "http://server.com/test", "test2"      ],
 ["/test/test2/",                     "/test",                  "test2"      ],
);

foreach my $arr ( @splits ) {
    my ($url,$left,$leaf) = @$arr;
    my ($pleft,$pleaf) = HTTP::DAV::Utils::split_leaf($url);
    my ($get_leaf) = HTTP::DAV::Utils::get_leafname($url);
    if ( 
          ($pleft eq $left) && 
          ($pleaf eq $leaf) && 
          ($get_leaf eq $leaf) 
       ) {
       ok(1);
    } else {
       print "BAD: $url-> $pleft, $pleaf (I thought: $left, $leaf)\n";
       ok(0);
    }
}
