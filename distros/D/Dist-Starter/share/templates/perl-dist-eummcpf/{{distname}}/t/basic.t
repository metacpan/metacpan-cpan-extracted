use Test2::V1
  -pragmas,
  -target => { CLASS => '{{main_module}}' },
  qw( pass plan );
plan 1;

pass( 'A passing test' )
