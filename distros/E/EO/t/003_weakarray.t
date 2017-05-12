# -*- perl -*-

# t/003_weakarray.t - similar tests to array, only with weakarrays

use Test::More no_plan => 1;

BEGIN { use_ok( 'EO::WeakArray' ); }

ok(my $object = EO::WeakArray->new());

isa_ok($object, 'EO::Array');
isa_ok($object, 'EO');
isa_ok($object->element, 'ARRAY');
can_ok($object,'push');
can_ok($object, 'pop');
can_ok($object,'shift');
can_ok($object,'unshift');
can_ok($object,'at');
can_ok($object,'count');
can_ok($object,'iterator');
can_ok($object,'splice');
can_ok($object,'delete');

ok(my $test   = EO->new());

ok( $object->push( $test ) );
is( $object->pop, $test );
ok( $object->unshift( $test ) );
is( $object->shift, $test );
ok( $object->push( $test ),"push test" );
is( $object->at( 0 ), $test,"wooo" );
is( $object->count, 1 );
is( $object->iterator, 1 );
ok( $object->delete( 0 ) );
is( $object->count, 0 );

ok( $object->push( qw( 1 2 3 4 5 6 7 8 9 ) ) );
is( $object->count, 9 );
ok( $object->delete( 4 ) );
is( $object->count, 8 );

eval {
  my $thing = EO::WeakArray->new_with_array();
};
ok($@);
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::InvalidParameters');

## testing to see if the delete fails.
eval {
  my $thing = EO::WeakArray->new_with_array(['one']);
  $thing->delete();
};
ok($@);
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::InvalidParameters');

ok( my $newarray = EO::WeakArray->new_with_array( qw( 10 14 22 37 5 9 2 ) ) );
ok( my $grepped = $newarray->select( sub { $_ <= 10 } ) );
is( $grepped->count, 4 );
is( $grepped->join(' '), '10 5 9 2' );

ok( my $totalarray = $newarray->do( sub { $_ + 10 } ) );
is( $totalarray->join(' '), '20 24 32 47 15 19 12' );

ok( my @array = @$totalarray );
is( CORE::join(' ', @array), '20 24 32 47 15 19 12' );
is($totalarray->[0], 20);

is( $totalarray->reverse->[6], 20 );
