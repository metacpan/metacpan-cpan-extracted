#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use MVC::Neaf;

throws_ok {
    neaf pre_route => sub { }, path => '/foo';
} qr(cannot.*path.*pre_route), 'no path in pre_route';

throws_ok {
    neaf pre_route => sub { }, exclude => '/foo';
} qr(cannot.*exclude.*pre_route), 'no exclude in pre_route';

throws_ok {
    neaf->add_hook( 'post_apocalypse' => sub { } );
} qr(illegal.*phase.*apocalypse), 'phase names are controlled';

throws_ok {
    neaf pre_logic => { foo => 42 };
} qr(coderef), 'hook must be a subroutine';

done_testing;
