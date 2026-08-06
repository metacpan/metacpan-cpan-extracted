use Test2::V1
  -target => { CLASS => 'Foo::Bar::Baz' },
  -pragmas,
  qw( pass plan );
plan 1;

pass( 'A passing test' )
