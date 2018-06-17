########################################################################
# Verifies period, generate, and seek limits
#   uses some k=17 taps that are known to be 65535 < period <= 2**17-1
#       # [17,2]        => 114_681: partial
#       # [17,4,2,1]    => 122_865: partial
#       # [17,3]        => 131_071: maximal
#       # [17,5]        => 131_071: maximal
########################################################################
use 5.006;
use strict;
use warnings;
use Test::More tests => 26;

use Math::PRBS;

my ($seq, $exp, $got, @g);

# verify PERIOD limits with [17,2]
$seq = Math::PRBS->new( taps => [17,2] );
is( $seq->description, 'PRBS from polynomial x**17 + x**2 + 1', '[17,2]->description');
is( $seq->oeis_anum, undef,                                     '[17,2]->oeis_anum');
is_deeply( $seq->taps(), [17,2],                                '[17,2]->taps' );
is( $seq->period(), undef,                                      '[17,2]->period()                           = not defined yet' );
is( $seq->period(force => 'estimate'), 2**17-1,                 '[17,2]->period(force => "estimate")        = estimate 2**k-1' );
is( $seq->period(force => 65535), undef,                        '[17,2]->period(force => 65535)             = force, but up to default limit' );
is( $seq->tell_i, 65535,                                        '[17,2]->period(force => 65535)->tell_i     = make sure it tried to force=>n' );
is( $seq->period(force => 'max'), 114_681,                      '[17,2]->period(force => "max")             = force, compute the full sequence' );

#verify generate_all() / generate_to_end() limits: they use the same limits-function, because generate_all calls generate_to_end
$got = $seq->generate_all();
is( length($got),  65_535,                                      '[17,2]->generate_all()                     = string length @ default limit');
is( $seq->tell_i,  65_535,                                      '[17,2]->generate_all()                     = tell_i() @ default limit');

$got = $seq->generate_to_end( limit => 70_000);
is( length($got),   4_465,                                      '[17,2]->generate_to_end(limit=>70000)      = string length: 70000-65535');
is( $seq->tell_i,  70_000,                                      '[17,2]->generate_to_end(limit=>70000)      = tell_i()');

$got = $seq->generate_to_end( limit => 'max');  # 131_071 > 114_681, so enough room
is( length($got),  44_681,                                      '[17,2]->generate_to_end(limit=>2**17-1)    = string length: 70000-65535');
is( $seq->tell_i, 114_681,                                      '[17,2]->generate_to_end(limit=>2**17-1)    = tell_i()');

# need to verify limits in generate_all_int for the default max-length (65535)
#   to save time, I am going to switch to a shorter sequence for arbitrary limit and max limit (below)
$got =()= $seq->generate_all_int();                             # =()= forces list context for generate_all_int, but translates to scalar context for $got
is( $got, 65535,                                                '[17,2]->generate_all_int()                 = list length (default limit: 65535)');

# verify seek_to_end limits: first, put to known location in long sequence
$seq->seek_to_i(1);
is( $seq->tell_i,       1,                                      '[17,2]->seek_to_n(1), ->tell_i()           = known location before seek_to_end');
# then verify that we haven't made it to the end yet
$seq->seek_to_end();    # limit = default 65535
is( $seq->tell_i,  65_535,                                      '[17,2]->seek_to_end(), ->tell_i()          = seek to default limit => 65535');
$seq->seek_to_end( limit => 131_071 );
is( $seq->tell_i, 114_681,                                      '[17,2]->seek_to_end(limit=>2**17-1), ->{i} = seek up to 131_071, but hit end of sequence');

# generate_all_int: arbitrary limit and 'max' limit, using a shorter (non-maximal) sequence
$seq = Math::PRBS->new( taps => [4,3,2] );
$got =()= $seq->generate_all_int( limit => 5 );
is( $got, 5,                                                    '[17,2]->generate_all_int(limit=>5)         = list length (arbitrary limit, less than period)');
$got =()= $seq->generate_all_int( limit => 13 );
is( $got, 7,                                                    '[17,2]->generate_all_int(limit=>13)        = list length (arbitrary limit, more than period, but less than 2**k-1)');
$got =()= $seq->generate_all_int( limit => 'max' );
is( $got, 7,                                                    '[17,2]->generate_all_int(limit=>"max")     = list length (max limit: period)');

# need to verify generate_all(limit => 'max') for a maximal, to make sure it computes correctly
$seq = Math::PRBS->new( taps => [17,3] );
$got = $seq->generate_all( limit => 'max');
is( length($got), 131_071,                                      '[17,3]->generate_all(limit=>"max")         = string length');
is( $seq->tell_i, 131_071,                                      '[17,3]->generate_all(limit=>"max")         = tell_i()');

# and verify seek_to_end( limit => 'max' );
$seq->seek_to_i(1);
$seq->seek_to_end( limit => 'max' );
is( $seq->tell_i, 131_071,                                      '[17,3]->seek_to_end(limit=>"max")          = verify seek to max end');

# need to verify period(force => 'max') for a maximal, to make sure it computes correctly
$seq = Math::PRBS->new( taps => [17,5] );
$got = $seq->period(force => 'max');
is( $got,         131_071,                                      '[17,5]->period(force=>"max")               = string length');
is( $seq->tell_i, 131_071,                                      '[17,5]->period(force=>"max")               = tell_i()');
