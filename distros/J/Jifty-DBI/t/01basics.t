#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 4;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @available_drivers ) {
SKIP: {
        use_ok('Jifty::DBI::Handle::'. $d);
        my $handle = get_handle( $d );
        isa_ok($handle, 'Jifty::DBI::Handle');
        isa_ok($handle, 'Jifty::DBI::Handle::'. $d);
        can_ok($handle, 'dbh');
}
}


1;
