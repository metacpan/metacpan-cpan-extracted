########################################################################
# Verifies new( taps => [list] )
########################################################################
use 5.006;
use strict;
use warnings;
use Test::More tests => 15;

use Math::PRBS;

my ($seq, $exp, $got, @g);

$seq = Math::PRBS->new( taps => [3,2] );
is( $seq->description, 'PRBS from polynomial x**3 + x**2 + 1',              'taps[3,2]->description');
is( $seq->oeis_anum, 'A011656',                                             'taps[3,2]->oeis_anum');
is_deeply( $seq->taps(), [3,2],                                             'taps[3,2]->taps                    = x**3 + x**2 + 1' );
$exp = '1011100';
$got = $seq->generate_all();
is( $got, $exp,                                                             'taps[3,2]->generate_all()          = full sequence');
is( $seq->period(), 2**3-1,                                                 'taps[3,2]->period                  = length of sequence' );

$seq = Math::PRBS->new( taps => [3,1] );
is( $seq->description, 'PRBS from polynomial x**3 + x**1 + 1',              'taps[3,1]->description');
is( $seq->oeis_anum, 'A011657',                                             'taps[3,1]->oeis_anum');
is_deeply( $seq->taps(), [3,1],                                             'taps[3,1]->taps                    = x**3 + x**1 + 1' );
$exp = '1110100';
$got = $seq->generate_all();
is( $got, $exp,                                                             'taps[3,1]->generate_all()          = full sequence');
is( $seq->period(), 2**3-1,                                                 'taps[3,1]->period                  = length of sequence' );

$seq = Math::PRBS->new( taps => [3,2,1] );
is( $seq->description, 'PRBS from polynomial x**3 + x**2 + x**1 + 1',       'taps[3,2,1]->description');
is( $seq->oeis_anum, undef,                                                 'taps[3,2,1]->oeis_anum');
is_deeply( $seq->taps(), [3,2,1],                                           'taps[3,2,1]->taps                  = x**3 + x**2 + x**1 + 1' );
$exp = '1100';
$got = $seq->generate_all();
is( $got, $exp,                                                             'taps[3,2,1]->generate_all()        = full sequence');
is( $seq->period(), 4,                                                      'taps[3,2,1]->period()              = it has now been computed, so dont need "force" anymore' );

done_testing();