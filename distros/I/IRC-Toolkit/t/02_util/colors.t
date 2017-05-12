use Test::More;
use strict; use warnings FATAL => 'all';

use_ok( 'IRC::Toolkit::Colors' );

my $str;
ok( $str = color('bold', "A string"), 'color() ok' );
cmp_ok( $str, 'eq', "\x02A string\x0f", 'bold string ok' );

$str = color('bold', "Start bold") ." end normal";
cmp_ok( $str,
  'eq',
  "\x02Start bold\x0f end normal",
  'bold interpolated ok'
);

ok has_color($str), 'bold str has_color()';
my $stripped = strip_color($str);
ok !has_color($stripped), 'stripped str !has_color()';
ok $stripped eq 'Start bold end normal', 'stripped str looks ok';

done_testing;
