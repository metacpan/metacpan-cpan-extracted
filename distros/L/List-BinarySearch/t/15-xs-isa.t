#!/usr/bin/env perl

use strict;
use warnings;

require B;

# Cargo-culted from Sub::Identify.  Thanks. ;)
sub get_code_info {
    my ($coderef) = @_;
    ref $coderef or return;
    my $cv = B::svref_2object($coderef);
    $cv->isa('B::CV') or return;
    # bail out if GV is undefined
    $cv->GV->isa('B::SPECIAL') and return;

    return ($cv->GV->STASH->NAME, $cv->GV->NAME);
};

use Test::More;

BEGIN{
  my $path = `perldoc -l List::BinarySearch::XS`;
  if( $path !~ m{List/BinarySearch/XS.pm} ) {
    plan skip_all =>
      'List::BinarySearch::XS must be installed for interoperability tests';
    done_testing();
    exit(0);        # Prereqs for this test aren't installed on target system.
  }
}

BEGIN{
  # Force pure-Perl testing.
  $ENV{List_BinarySearch_PP} = 0; ## no critic (local)
}


use List::BinarySearch qw( binsearch );


my( $pkg, $subname ) = get_code_info( \&binsearch );

is( $pkg, "List::BinarySearch::XS",
    '$List::BinarySearch::PP=1 forces pure-Perl implementation.'
);

is( \&binsearch, \&List::BinarySearch::XS::binsearch,
    "Stringified coderefs match for XS implementation in package main."
);
is( \&List::BinarySearch::binsearch, \&List::BinarySearch::XS::binsearch,
    'Stringified coderefs match for XS implementation in package List::BinarySearch.'
);

done_testing;
