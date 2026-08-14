use Test2::V1
  -pragmas,
  -target => { CLASS => 'Foo::Bar::Baz' },
  qw( pass plan );
plan 1;

pass( 'A passing test' )
