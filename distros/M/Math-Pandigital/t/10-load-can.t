#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Math::Pandigital' ) || BAIL_OUT();
}

diag( "Testing Math::Pandigital " .
      "$Math::Pandigital::VERSION, Perl $], $^X"
);


can_ok(
    'Math::Pandigital',
    qw( new base zeroless unique )
);

done_testing();
