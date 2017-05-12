# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More no_plan => 1;

BEGIN { use_ok( 'EO::Hash' ); }

ok(my $object = EO::Hash->new());

isa_ok($object, 'EO::Hash');
isa_ok($object, 'EO::Collection');
isa_ok($object, 'EO');

can_ok($object,'keys');
ok(my $array = $object->keys);
isa_ok($array, 'EO::Array');
isa_ok($array, 'EO::Collection');
isa_ok($array, 'EO');
can_ok($object,'at');
ok($object->at('array', $array));
is($array, $object->at('array'));
can_ok($object, 'count');
is(
   $object->keys->count,
   $object->values->count,
   "equal number of keys and values"
  );
is($object->count, 1);
ok($object->at('whoo',$array));
is($object->count,2);
ok($object->delete( 'whoo' ));
is($object->count,1);
ok($object->delete('array'));
is($object->count,0);

eval {
  my $thing = EO::Hash->new_with_hash();
};
ok($@, "got an exception: $@");
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::InvalidParameters');

eval {
  my $thing = EO::Hash->new_with_hash( { one => 'thing' } );
  $thing->delete();
};
ok($@, "got an exception: $@");
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::InvalidParameters');

eval {
  my $thing = EO::Collection->new();
  $thing->count;
};
ok($@);
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::Method');
isa_ok($@,'EO::Error::Method::Abstract');


my $hash = EO::Hash->new();
$hash->at( test1 => 'foo' );
$hash->at( test2 => 'bar' );
$hash->at( test3 => 'baz' );


ok( my $pair = $hash->pair_for( 'test3' ) );
is( $pair->key, 'test3' );
is( $pair->value, 'baz' );

my $tarray = EO::Array->new();
ok(
   $hash->do(
	     sub {
	       $_->key =~ /(\d+)$/;
	       my $numeral = $1 - 1;
	       $tarray->at( $numeral, $_->key );
	       $_
	     }
	    )
  );
is( $tarray->join(''), 'test1test2test3' );

ok( my $resulthash = $hash->select( sub { $_->value eq 'foo' } ) );
is( $resulthash->count, 1 );
is( $resulthash->at( 'test1' ), 'foo' );

is( $resulthash->{ 'test1' }, 'foo' );
is( join(' ', sort keys %$hash), 'test1 test2 test3' );

ok( $resulthash->has( 'test1' ) );

eval {
  ok( $resulthash->add() );
};
ok($@,"should get an exception");
isa_ok( $@, 'EO::Error' );

ok( $resulthash->add( EO::Pair->new()->key('foo')->value('bar') ) );
ok( $resulthash->has( 'foo' ) );
