use strict; use warnings FATAL => 'all';

use Test::More;
use Test::TypeTiny;

use Types::Standard -types;

use List::Objects::Types -all;
use List::Objects::WithUtils;

# array/hash
should_pass array(), ArrayObj;
should_pass hash(),  HashObj;

# immarray
ok_subtype ArrayObj, ImmutableArray;
should_pass immarray(), ArrayObj;
should_pass immarray(), ImmutableArray;

# immhash
ok_subtype HashObj, ImmutableHash;
should_pass immhash(), HashObj;
should_pass immhash(), ImmutableHash;

# array_of
my $typed = array_of(Int() => 1 .. 4);
should_pass $typed, ArrayObj;
should_pass $typed, TypedArray;
should_pass $typed, TypedArray[Int];
should_fail $typed, TypedArray[Num];
should_fail $typed, TypedArray[GlobRef];

# immarray_of
# FIXME

# hash_of
my $htyped = hash_of(Int() => ( foo => 1, baz => 2 ) );
should_pass $htyped, HashObj;
should_pass $htyped, TypedHash;
should_pass $htyped, TypedHash[Int];
should_fail $htyped, TypedHash[Num];
should_fail $htyped, TypedHash[GlobRef];

# immhash_of
# FIXME

# inflated
my $inflated = hash(foo => 1, bar => 2)->inflate;
should_pass $inflated, InflatedHash;
should_fail $inflated, HashObj;
should_pass $inflated, InflatedHash[qw/foo bar/];
should_fail $inflated, InflatedHash[qw/foo bar baz/];

# failures
should_fail [],  ArrayObj;
should_fail [],  ImmutableArray;
should_fail [],  TypedArray;
should_fail array(), ImmutableArray;
should_fail array(), TypedArray;
should_fail +{}, HashObj;
should_fail +{}, TypedHash;
should_fail hash(), TypedHash;
should_fail +{},    InflatedHash;
should_fail hash(), InflatedHash;

# unions
should_pass [],       (ArrayRef | ArrayObj);
should_pass array(),  (ArrayRef | ArrayObj);
should_fail 'foo',    (ArrayRef | ArrayObj);

# helpers
ok is_ArrayObj(array), 'is_ArrayObj ok';
ok is_HashObj(hash),   'is_HashObj ok';
ok is_ImmutableArray(immarray), 'is_ImmutableArray ok';
ok is_ImmutableHash(immhash), 'is_ImmutableHash ok';

# coercions
my $coerced = ArrayObj->coerce([]);
ok $coerced->count == 0, 'ArrayRef coerced to ArrayObj ok';

$coerced = ImmutableArray->coerce($coerced);
ok is_ImmutableArray($coerced), 'ArrayObj coerced to ImmutableArray ok';
$coerced = ImmutableArray->coerce([]);
ok is_ImmutableArray($coerced), 'ArrayRef coerced to ImmutableArray ok';

$coerced = HashObj->coerce(+{foo => 1});
ok $coerced->keys->count == 1, 'HashRef coerced to HashObj ok';

$coerced = ImmutableHash->coerce($coerced);
ok $coerced->keys->count == 1, 'HashObj coerced to ImmutableHash ok';
$coerced = ImmutableHash->coerce(+{foo => 1});
ok $coerced->keys->count == 1, 'HashRef coerced to ImmutableHash ok';

my $RoundedInt = Int->plus_coercions(Num, 'int($_)');
$coerced = (TypedArray[$RoundedInt])->coerce([ 1, 2, 3, 4.1 ]);
should_pass $coerced, TypedArray[Int];
is_deeply(
  [  $coerced->all ],
  [ 1..4 ],
  'TypedArray inner coercions worked',
);

$coerced = (ImmutableTypedArray[$RoundedInt])->coerce([ 1, 2, 3, 4.1 ]);
should_pass $coerced, ImmutableTypedArray[Int];
is_deeply(
  [ $coerced->all ],
  [ 1 .. 4 ],
  'ImmutableTypedArray'
);

$coerced = (TypedHash[$RoundedInt])->coerce(
  +{ foo => 1, bar => 2, baz => 3.14}
);
should_pass $coerced, TypedHash[Int];
is_deeply(
  +{ $coerced->export },
  +{ foo => 1, bar => 2, baz => 3 },
  'TypedHash inner coercions worked'
);

$coerced = (ImmutableTypedHash[$RoundedInt])->coerce(
  +{ foo => 1, bar => 2, baz => 3.14 }
);
should_pass $coerced, ImmutableTypedHash[Int];
is_deeply(
  +{ $coerced->export },
  +{ foo => 1, bar => 2, baz => 3 },
  'ImmutableTypedHash inner coercions worked',
);

$coerced = InflatedHash->coerce(+{ foo => 1, bar => 2 });
should_pass $coerced, InflatedHash;
ok $coerced->foo == 1 && $coerced->bar == 2,
  'HashRef coerced to InflatedHash ok';

$coerced = InflatedHash->coerce( hash(foo => 1, bar => 2) );
should_pass $coerced, InflatedHash;
ok $coerced->foo == 1 && $coerced->bar == 2,
  'HashObj coerced to InflatedHash ok';

done_testing;
