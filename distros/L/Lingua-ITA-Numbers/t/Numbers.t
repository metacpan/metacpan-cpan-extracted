#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;

use Test::More;

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::ITA::Numbers');
    $tests++;
}

use Lingua::ITA::Numbers           qw(:ALL);

# }}}

# {{{ number_to_it


 my $nw = [
     [
         1,
         'uno',
         '1 in Italian',
     ],
     [
         100001,
         'centomilauno',
         '100001 in Italian',
     ],
     [
         12,
         'dodici',
         '12 in Italian',
     ],
     [
         21,
         'ventuno',
         '21 in Italian',
     ],
     [
         31,
         'trentuno',
         '31 in Italian',
     ],
     [
         123456,
         'centoventitremilaquattrocentocinquantasei',
         '123456 in Italian',
     ],
     [
         12345678901,
         'dodici miliardi trecentoquarantacinque milioni seicentosettantottomilanovecentouno',
         '12345678901 in Italian',
     ],
     [
         undef,
         'zero',
         'undef args -> 0',
     ],
 ];

    for my $test (@{$nw}) {
    my $got = number_to_it($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}
# {{{ object access tests

print "[object tests...]\n";

my @TestData = (
	       1 => "uno",
	       100001 => "centomilauno",
	       12 => "dodici",
	       21 => "ventuno",
	       31 => "trentuno",
	       28 => "ventotto",
	       123456 => "centoventitremilaquattrocentocinquantasei",
	       '123' => "centoventitre",
               '12345678901' => 
	       "dodici miliardi trecentoquarantacinque milioni seicentosettantottomilanovecentouno"
	    );

while (@TestData) {
    my $num = Lingua::ITA::Numbers->new(shift @TestData);
    my $str = shift @TestData;
    is($str, $num->get_string(), "$str in Italian");
    $tests++;
}

# }}}

done_testing($tests);

__END__
