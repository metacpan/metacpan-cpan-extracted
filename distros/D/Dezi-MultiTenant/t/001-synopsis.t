#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Dezi::MultiTenant');

ok( my $dmt = Dezi::MultiTenant->app(
        {   '/foo' => Dezi::Config->new( {} ),
            '/bar'  => Dezi::Config->new( {} ),
        }
    ),
    "new multitenant app()"
);
