#!perl

# This test was provided by Tom from eborcom.com as a part of 
# the following bugreport https://rt.cpan.org/Ticket/Display.html?id=82838

use strict;
use warnings;

use Geo::Cloudmade ();
use Test::More;

if (exists $ENV{CLOUDMADE_API_KEY}) {
    my $geo = Geo::Cloudmade->new($ENV{CLOUDMADE_API_KEY});
    isa_ok $geo, 'Geo::Cloudmade';
    my $route;
    eval {
        $route = $geo->get_route(
            [qw(51.51103 -0.1122)],
            [qw(51.51666 -0.1125)],
            { type => 'foot' },
        );
    };
    ok ! $@, 'Route generation did not die';
    if (exists $route->{status_message}) {
        unlike $route->{status_message}, qr/wrong route type/i, 'No error message';
    }
}
else { # no key - no tests
  ok 1
}

done_testing;
