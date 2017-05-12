
use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Math::Goedel'); }

is(Math::Goedel::goedel(9), 512);
is(Math::Goedel::goedel(81), 768);
is(Math::Goedel::goedel(230), 108);
# rt 88842
is(Math::Goedel::goedel(10000), 2);
{ use Math::BigInt;
is(Math::Goedel::goedel(4999, bigint => 1), Math::BigInt->new('24821251455656250000'));
}


is(Math::Goedel::goedel(q/9/), 512);
is(Math::Goedel::goedel(q/81/), 768);
is(Math::Goedel::goedel(q/230/), 108);
is(Math::Goedel::goedel(q/10000/), 2);
{ use Math::BigInt;
is(Math::Goedel::goedel(q/4999/, bigint => 1), Math::BigInt->new('24821251455656250000'));
}

# error
$@ = undef;
eval { Math::Goedel::goedel(-1); };
ok($@);
$@ = undef;
eval { Math::Goedel::goedel(9.5); };
ok($@);
$@ = undef;
eval { Math::Goedel::goedel(q/a/); };
ok($@);

# with offset

is(Math::Goedel::goedel(9, q/offset/ => 1), 2**10);
is(Math::Goedel::goedel(81, q/offset/ => 1), 2**9 * 3**2);
is(Math::Goedel::goedel(230, q/offset/ => 1), 2**3 * 3**4 * 5**1);
is(Math::Goedel::goedel(9, q/offset/ => 2), 2**11);
is(Math::Goedel::goedel(81, q/offset/ => 3), 2**11 * 3**4);
is(Math::Goedel::goedel(230, q/offset/ => 4), 2**6 * 3**7 * 5**4);

# with offset error
$@ = undef;
eval { Math::Goedel::goedel(9, offset => -1); };
ok($@);
$@ = undef;
eval { Math::Goedel::goedel(9, offset => 1.8); };
ok($@);
$@ = undef;
eval { Math::Goedel::goedel(9, offset => q/a/); };
ok($@);

# with reverse

is(Math::Goedel::goedel(9, q/reverse/ => 1), 2**9);
is(Math::Goedel::goedel(81, q/reverse/ => 1), 2**1 * 3**8);
is(Math::Goedel::goedel(230, q/reverse/ => 1), 2**0 * 3**3 * 5**2);
is(Math::Goedel::goedel(10000, reverse => 1), 2**0 * 3**0 * 5**0 * 7**0 * 11**1);
{ use Math::BigInt;
is(Math::Goedel::goedel(Math::BigInt->new(10000), reverse => 1), 2**0 * 3**0 * 5**0 * 7**0 * 11**1);
}

# with offset and reverse 
is(Math::Goedel::goedel(9, q/offset/ => 2, q/reverse/ => 1), 2**11);
is(Math::Goedel::goedel(81, q/offset/ => 1, q/reverse/ => 1), 2**2 * 3**9);
is(Math::Goedel::goedel(230, q/offset/ => 0, q/reverse/ => 1), 2**0 * 3**3 * 5**2);

done_testing;
