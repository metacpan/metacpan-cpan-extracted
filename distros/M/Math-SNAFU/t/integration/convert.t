use Test2::V0 -target => 'Math::SNAFU';
use Math::SNAFU qw( snafu_to_decimal decimal_to_snafu );

while ( <DATA> ) {
	chomp;
	my ( $decimal, $snafu) = m/(-?\d+)\s*(\S+)/ or next;

	is( snafu_to_decimal($snafu), $decimal, "snafu_to_decimal('$snafu') == $decimal" );
	is( decimal_to_snafu($decimal), $snafu, "decimal_to_snafu($decimal) eq '$snafu'" );
}

done_testing;

__DATA__
1            1
2            2
3            1=
4            1-
5            10
6            11
7            12
8            2=
9            2-
10           20
15           1=0
20           1-0
2022         1=11-2
12345        1-0---0
314159265    1121-1110-1=0

1747         1=-0-2
906          12111
198          2=0=
11           21
201          2=01
31           111
1257         20012
32           112
353          1=-1=
107          1-12
7            12
3            1=
37           122

0            0
