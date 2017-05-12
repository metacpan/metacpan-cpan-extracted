use Test::More tests => 9;

use strict;
use warnings;

BEGIN {
    use_ok( 'File::SAUCE' );
}

my $sauce = File::SAUCE->new;
isa_ok( $sauce, 'File::SAUCE' );

my $expected;

$expected = <<'END';
M&E-!54-%,#`@("`@("`@("`@("`@("`@("`@("`@("`@("`@("`@("`@("`@
M("`@("`@("`@("`@("`@("`@("`@("`@("`@("`@("`@("`@("`R,#`S,3(P
G-P`````````````````````@("`@("`@("`@("`@("`@("`@("`@
END

$sauce->date( '20031207' );
is( $sauce->date->ymd, '2003-12-07', 'Date' );

my $out = $sauce->as_string;

is( length( $out ), 129, 'Length' );
is( pack( 'u*', $out ), $expected, 'As String' );

$expected = <<'END';
M&E-!54-%,#!T:&4@<V5V96YT:"!S96%L("`@("`@("`@("`@("`@("`@(&YA
M<&%L;2`@("`@("`@("`@("`@8VEA("`@("`@("`@("`@("`@("`Q.3DW,3`Q
G,%B=```!`5``&0`````````@("`@("`@("`@("`@("`@("`@("`@
END

$sauce->read( file => 't/data/NA-SEVEN.CIA' );
$out = $sauce->as_string;

is( length( $out ), 129, 'Length' );
is( pack( 'u*', $out ), $expected, 'As String' );

$expected = <<'END';
M&D-/34Y45&\@<'5R8VAA<V4@>6]U<B!W:&ET92!T<F%S:"!A;G-I.B`@<V5N
M9"!C87-H+V-H96-K('1O("`@("`@("`@(&ME:71H(&YA9&]L;GD@+R`T,2!L
M;W)E='1O(&1R:79E("\@8VAE96MT;W=A9V$L(&YY("\@,30R,C4@("`@("!M
M86ME(&-H96-K<R!P87EA8FQE('1O(&ME:71H(&YA9&]L;GDO=7,@9G5N9',@
M;VYL>2`@("`@("`@("`@("`@-2!D;VQL87)S(#T@,3`P(&QI;F5S("T@,3`@
M9&]L;&%R<R`](#(P,"!L:6YE<R`@("`@("`@("`@("`@("`@(%-!54-%,#!2
M;W5T92`V-C8@("`@("`@("`@("`@("`@("`@("`@("`@(%=H:71E(%1R87-H
M("`@("`@("`@04-I1"!0<F]D=6-T:6]N<R`@("`Q.3DW,#0P,>ZG```!`5``
>M```````!``@("`@("`@("`@("`@("`@("`@("`@
END

$sauce->read( file => 't/data/W7-R666.ANS' );
$out = $sauce->as_string;

is( length( $out ), 390, 'Length' );
is( pack( 'u*', $out ), $expected, 'As String' );
