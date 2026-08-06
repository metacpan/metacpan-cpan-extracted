use Test2::V1
  -target => { CLASS => '{{main_module}}' },
  -pragmas,
  qw( pass plan );
plan 1;

pass( 'A passing test' )
