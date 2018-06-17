########################################################################
# Verifies the integer sequence generation
########################################################################
use 5.006;
use strict;
use warnings;
use Test::More tests => 10;

use Math::PRBS;

my $seq = Math::PRBS->new( taps => [4,1] );
is( my $p = $seq->period( force => 'max' ), 15,                                 '->period()' );
is( my $k = $seq->k_bits(), 4,                                                  '->k_bits()' );
is( $seq->polynomial_degree(), $k,                                              '->polynomial_degree() eq ->k_bits()' );
is( \&Math::PRBS::polynomial_degree, \&Math::PRBS::k_bits,                      '&polynomial_degree() eq -&_bits() -- code equality');

$seq->rewind();
is_deeply( [$seq->generate_int()], [15],                                        '->generate_int() -- first (list)' );
is_deeply( [$seq->generate_int(4)], [5,9,1,14],                                 '->generate_int(4) -- next four (list)' );
is( $seq->generate_int(), '11',                                                 '->generate_int() -- next (scalar/string)' );
is( $seq->generate_int(4), '2,3,13,6',                                          '->generate_int(4) -- next four (scalar/string)' );

is( $seq->generate_all_int(), '15,5,9,1,14,11,2,3,13,6,4,7,10,12,8',            '->generate_all_int() -- all integers, starting from the beginning of the sequence (as scalar/string)' );
is_deeply( [$seq->generate_all_int()], [15,5,9,1,14,11,2,3,13,6,4,7,10,12,8],  '->generate_all_int() -- (as list)' );

done_testing();
