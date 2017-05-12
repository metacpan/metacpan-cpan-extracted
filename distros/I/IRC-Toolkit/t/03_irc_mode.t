use Test::More;
use strict; use warnings FATAL => 'all';

use_ok( 'IRC::Mode::Single' );

my $mode = new_ok( 'IRC::Mode::Single' =>
  [ '+', 'o', 'avenj' ]
);
cmp_ok( $mode->flag, 'eq', '+', 'flag() looks ok' );
cmp_ok( $mode->char, 'eq', 'o', 'char() looks ok' );
cmp_ok( $mode->param, 'eq', 'avenj', 'param() looks ok' );
cmp_ok( $mode->as_string, 'eq', '+o avenj', 'as_string looks ok' );
cmp_ok( "$mode", 'eq', '+o avenj', 'stringification looks ok' );
cmp_ok( ref $mode->export, 'eq', 'ARRAY', 'export() returned ARRAY' );

done_testing;
