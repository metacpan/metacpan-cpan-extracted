
use strict;
use warnings;

use Test::More tests => 4;

use HTTP::Async;

foreach my $number ( 0, 3 ) {
    my $q2 = HTTP::Async->new( max_redirects => $number );
    ok $q2, "created object";
    is $q2->max_redirect, $number, "got $number";
}
