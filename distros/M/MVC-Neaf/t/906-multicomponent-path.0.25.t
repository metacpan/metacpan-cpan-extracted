#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };

    MVC::Neaf->route( foo => bar => sub { +{}} );

    is scalar @warn, 1, "1 warning issued";
    like $warn[0], qr/NEAF.*DEPRECATED/, "warning of deprecation";

    is_deeply [ keys %{ MVC::Neaf->get_routes } ], [ "/foo/bar" ],
        "Route still registered";
};

done_testing;
