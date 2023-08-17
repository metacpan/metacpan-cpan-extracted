#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

use Docker::CLI::Wrapper::Container ();

{
    my $obj = Docker::CLI::Wrapper::Container->new(
        { container => "fortune-mod--deb--test-build", sys => "debian:10", }, );

    # TEST
    ok( $obj, "object was instantiated." );

    # TEST
    is(
        scalar( $obj->container ),
        "fortune-mod--deb--test-build",
        "Silly test for the 'container' accessor."
    );
}
