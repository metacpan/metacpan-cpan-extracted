use strict;
use warnings;
use Config;
use Test::More;
use Math::Rand48::Cursor;

# Seed-coercion corner cases: how from_seed48 reverses non-integer, negative,
# and oversized seeds vs a live srand($seed); rand().

# Live checks only mean something if the host rand() is Perl's drand48.
my $LIVE = $Config{randfunc} eq 'Perl_drand48';
diag $LIVE
  ? "host rand() is Perl_drand48: live checks active"
  : "host rand() is $Config{randfunc}, not Perl_drand48: live checks skipped";

# Non-negative integers of any size reverse cleanly (mod 2^48 wraps >= 2^32).
{
    is(
        Math::Rand48::Cursor->from_seed48( 2**48 - 1 )->state->bstr,
        Math::Rand48::Cursor->from_seed48( 2**32 - 1 )->state->bstr,
        'seed wraps mod 2^32: from_seed48(2^48-1) == from_seed48(2^32-1)'
    );

    for my $seed ( 0, 1, 12345, 2**32 + 5 ) {
      SKIP: {
            skip 'rand() is not drand48 here', 1 unless $LIVE;
            srand($seed);
            my $live = Math::Rand48::Cursor->from_rand( rand() )->state;
            my $pred = Math::Rand48::Cursor->from_seed48($seed)->forward->state;
            is $pred->bstr, $live->bstr, "from_seed48($seed) matches live srand($seed)";
        }
    }
}

# Fractional seed: truncated toward zero (srand(3.7) == srand(3)).
{
    is(
        Math::Rand48::Cursor->from_seed48(3.7)->state->bstr,
        Math::Rand48::Cursor->from_seed48(3)->state->bstr,
        'from_seed48(3.7) truncates toward zero == from_seed48(3)'
    );
    is(
        Math::Rand48::Cursor->from_seed48(3.9)->state->bstr,
        Math::Rand48::Cursor->from_seed48(3)->state->bstr,
        'from_seed48(3.9) truncates toward zero == from_seed48(3)'
    );

  SKIP: {
        skip 'rand() is not drand48 here', 1 unless $LIVE;
        srand(3.7);
        my $live = Math::Rand48::Cursor->from_rand( rand() )->state;
        my $pred = Math::Rand48::Cursor->from_seed48(3.7)->forward->state;
        is $pred->bstr, $live->bstr, 'from_seed48(3.7) matches live srand(3.7)';
    }
}

# Negative seed: absolute value (srand(-$n) == srand($n) in Perl; libc differs).
{
    is(
        Math::Rand48::Cursor->from_seed48(-1)->state->bstr,
        Math::Rand48::Cursor->from_seed48(1)->state->bstr,
        'from_seed48(-1) == from_seed48(1) (absolute value, matches Perl srand)'
    );
    is(
        Math::Rand48::Cursor->from_seed48(-1000)->state->bstr,
        Math::Rand48::Cursor->from_seed48(1000)->state->bstr,
        'from_seed48(-1000) == from_seed48(1000)'
    );

  SKIP: {
        skip 'rand() is not drand48 here', 3 unless $LIVE;
        for my $seed ( -1, -1000, -3.7 ) {
            srand($seed);
            my $live = Math::Rand48::Cursor->from_rand( rand() )->state;
            my $pred = Math::Rand48::Cursor->from_seed48($seed)->forward->state;
            is $pred->bstr, $live->bstr, "from_seed48($seed) matches live srand($seed)";
        }
    }
}

# from_rand input domain: out-of-range 1.0 wraps to state 0 rather than erroring.
{
    is( Math::Rand48::Cursor->from_rand(1.0)->state->bstr, '0',
        'from_rand(1.0) wraps to state 0 (out-of-range input)' );
    is( Math::Rand48::Cursor->from_rand(0)->state->bstr, '0', 'from_rand(0) is state 0' );
}

# Non-numeric seeds croak rather than seeding from NaN.
{
    for my $bad ( 'foo', 'inf', '-inf', 'NaN' ) {
        eval { Math::Rand48::Cursor->from_seed48($bad) };
        like $@, qr/finite number/, "from_seed48('$bad') croaks";
    }
}

done_testing;
