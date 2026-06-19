use strict;
use warnings;
use Test::More;
use Math::Rand48::Cursor;

# A non-integer seek count once became NaN and spun _affine_pow forever;
# seek() must reject it up front rather than loop.
for my $bad ( 'inf', '-inf', 'NaN', 'foo', '3.9' ) {
    eval { Math::Rand48::Cursor->new( state => 1 )->seek($bad) };
    like $@, qr/finite integer/, "seek('$bad') croaks";
}

# Valid integer-ish forms still work.
my $a = Math::Rand48::Cursor->new( state => 1 )->seek('1e3')->state->bstr;
my $b = Math::Rand48::Cursor->new( state => 1 )->seek(1000)->state->bstr;
is $a, $b, 'seek("1e3") == seek(1000)';

done_testing;
