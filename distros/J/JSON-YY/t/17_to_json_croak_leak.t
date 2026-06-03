use strict;
use warnings;
use Test::More;
BEGIN {
    eval { require Test::LeakTrace; Test::LeakTrace->import('no_leaks_ok'); 1 }
        or plan skip_all => 'Test::LeakTrace required for this leak test';
}
use JSON::YY qw(encode_json);   # also activates the encode_json keyword

# When convert_blessed calls TO_JSON and the returned value is itself not
# encodable, the recursive encode croaks. The TO_JSON result (which the encoder
# refcount-bumps to survive the call's FREETMPS) must be released on the croak
# unwind, not leaked.
{
    package JSONYY_Leaky;
    sub new { bless {}, shift }
    sub TO_JSON { return { x => bless({}, 'JSONYY_NoToJson') } }  # nested blessed, no TO_JSON
}

my $coder = JSON::YY->new->convert_blessed;

# Warm up method-resolution / package-stash caches first so their one-time
# allocations are not mistaken for a leak.
eval { $coder->encode(JSONYY_Leaky->new) };

no_leaks_ok {
    eval { $coder->encode(JSONYY_Leaky->new) };
} 'TO_JSON result is not leaked when the recursive encode croaks';

# The encode_json keyword (a custom op, distinct from the OO encoder) must
# likewise not leak its output buffer when the encode croaks part-way.
{
    my $cyclic = {};
    $cyclic->{loop} = $cyclic;          # cyclic -> max-depth croak mid-encode
    eval { encode_json($cyclic) };       # warm up caches
    no_leaks_ok {
        eval { encode_json($cyclic) };
    } 'keyword encode_json does not leak its buffer when the encode croaks';
}

done_testing;
