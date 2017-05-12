#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('LWPx::UserAgent::Cached');
}

my $mech = LWPx::UserAgent::Cached->new;

ok( !defined( $mech->is_cached ), "is_cached should default to undef" );

