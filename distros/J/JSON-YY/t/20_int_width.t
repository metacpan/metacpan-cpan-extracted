use strict;
use warnings;
use Test::More;
use Config;
use JSON::YY qw(decode_json);

# yyjson always parses JSON integers as 64-bit. JSON::YY must not silently
# truncate when a value exceeds the platform IV/UV: on 32-bit-IV perls it
# falls back to an NV (double); on 64-bit-IV perls the value stays exact.
# Regression: an armv6l (ivsize=4) smoker decoded 9999999999999999 as a
# truncated 1874919423. This test needs no JSON::XS, so it runs everywhere
# (unlike t/09, which skips without it) and exercises the fix on every config.

# Relative closeness, robust whether the value comes back as an IV/UV or an NV.
sub near {
    my ($got, $want) = @_;
    return abs($got - $want) < 1 if abs($want) < 1;
    return abs($got / $want - 1) < 1e-9;
}

# ~1e16: exceeds 32-bit UV (4294967295) but is representable as a double
{
    my $v = decode_json('[9999999999999999]')->[0];
    ok near($v, 9999999999999999), 'large uint not truncated' or diag "got $v";
}

# 2^32: the first value a 32-bit UV cannot hold
{
    my $v = decode_json('[4294967296]')->[0];
    ok near($v, 4294967296), '2^32 survives decode' or diag "got $v";
}

# UINT64_MAX
{
    my $v = decode_json('[18446744073709551615]')->[0];
    ok near($v, 18446744073709551615), 'UINT64_MAX survives decode' or diag "got $v";
}

# large negative beyond 32-bit range: -(2^53+1)
{
    my $v = decode_json('[-9007199254740993]')->[0];
    ok near($v, -9007199254740993), 'large negative survives decode' or diag "got $v";
}

# small integers stay exact integers on every platform
{
    is decode_json('[42]')->[0],  42, 'small positive int exact';
    is decode_json('[-7]')->[0],  -7, 'small negative int exact';
    is decode_json('[0]')->[0],    0, 'zero exact';
}

# on 64-bit-IV perls the big values must come back EXACT, not as a lossy NV
SKIP: {
    skip 'exact 64-bit integers require ivsize >= 8', 2 if $Config{ivsize} < 8;
    is decode_json('[9999999999999999]')->[0],
        9999999999999999, '64-bit: large int exact';
    is decode_json('[18446744073709551615]')->[0],
        18446744073709551615, '64-bit: UINT64_MAX exact';
}

done_testing;
