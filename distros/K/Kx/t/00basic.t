#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Kx') }

my $fail = 0;
foreach my $constname (
    qw(
    KC KD KE KF KG KH KI KJ KM KS KT KU KV KZ XD XT)
  )
{
    no strict 'refs';
    next if ( eval "my \$a = 'Kx::$constname'->(); 1" );
    if ( $@ =~ /^Your vendor has not defined Kx macro $constname/ ) {
        print "# pass: $@";
    }
    else {
        print "# fail: $@";
        $fail = 1;
    }

}

ok( $fail == 0, 'Constants' );

