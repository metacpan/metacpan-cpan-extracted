use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Gentoo::PerlMod::Version qw( :all );

sub b {
  my ( $z, $x, $y ) = @_;
  is( gentooize_version($x), $y, "$x -> $y expanding ( icode $z )" );
}

# 1..10
b( 1,  '0',        '0.0.0' );
b( 2,  '1',        '1.0.0' );
b( 3,  '0.1',      '0.100.0' );
b( 4,  '1.1',      '1.100.0' );
b( 5,  '0.01',     '0.10.0' );
b( 6,  '1.01',     '1.10.0' );
b( 7,  '1.001',    '1.1.0' );
b( 8,  '1.0001',   '1.0.100' );
b( 9,  '1.00001',  '1.0.10' );
b( 10, '1.000001', '1.0.1' );
;    # 10 .. 19
b( 11, '1.0000001',      '1.0.0.100' );
b( 12, '1.00000001',     '1.0.0.10' );
b( 13, '1.000000001',    '1.0.0.1' );
b( 14, '1.0000000001',   '1.0.0.0.100' );
b( 15, '1.00000000001',  '1.0.0.0.10' );
b( 16, '1.000000000001', '1.0.0.0.1' );
b( 17, '1.0.1',          '1.0.1' );
b( 18, '1.0.01',         '1.0.1' );
b( 19, '1.0.001',        '1.0.1' );
b( 20, '1.0.10',         '1.0.10' );
;    # 20 .. 29
b( 21, '1.0.010',          '1.0.10' );
b( 22, '1.0.0010',         '1.0.10' );
b( 23, '1.1.1',            '1.1.1' );
b( 24, '1.1.01',           '1.1.1' );
b( 25, '1.1.001',          '1.1.1' );
b( 26, '1.1.10',           '1.1.10' );
b( 27, '1.1.010',          '1.1.10' );
b( 28, '1.1.0010',         '1.1.10' );
b( 29, '1.1.000000000010', '1.1.10' );
b( 30, '1.10.1',           '1.10.1' );
;    # 30 .. 39
b( 31, '1.10.01',           '1.10.1' );
b( 32, '1.10.001',          '1.10.1' );
b( 33, '1.10.10',           '1.10.10' );
b( 34, '1.10.010',          '1.10.10' );
b( 35, '1.10.0010',         '1.10.10' );
b( 36, '1.10.000000000010', '1.10.10' );
b( 37, '1.010.1',           '1.10.1' );
b( 38, '1.010.01',          '1.10.1' );
b( 39, '1.010.001',         '1.10.1' );
b( 40, '1.010.10',          '1.10.10' );
;    # 40 .. 49
b( 41, '1.010.010',          '1.10.10' );
b( 42, '1.010.0010',         '1.10.10' );
b( 43, '1.010.000000000010', '1.10.10' );

my $e;
isnt( $e = exception { gentooize_version('1.6.A6FGHKE') }, undef, 'Ascii is bad' );     # 44
isnt( $e = exception { gentooize_version('1.6-TRIAL') },   undef, '-TRIAL is bad' );    # 45
isnt( $e = exception { gentooize_version('1.6_0') },       undef, 'x_y is bad' );       # 46
isnt( $e = exception { gentooize_version( '1.6.A6FGHKE', { lax => 1 } ) }, undef, 'Ascii is bad ( even with lax => 1 )' );    # 47
is( $e = exception { gentooize_version( '1.6-TRIAL',   { lax => 1 } ) }, undef, '-TRIAL is ok with lax => 1' );               # 48
is( $e = exception { gentooize_version( '1.6_0',       { lax => 1 } ) }, undef, 'x_y is ok with lax => 1 ' );                 # 49
is( $e = exception { gentooize_version( '1.6.A6FGHKE', { lax => 2 } ) }, undef, 'Ascii is ok with lax => 2 )' );              # 50
is( $e = exception { gentooize_version( '1.6-TRIAL',   { lax => 2 } ) }, undef, '-TRIAL is ok with lax => 2' );               # 51
is( $e = exception { gentooize_version( '1.6_0',       { lax => 2 } ) }, undef, 'x_y is ok with lax => 2 ' );                 # 52

is( gentooize_version( '1.6-TRIAL',   { lax => 1 } ), '1.600.0_rc',   'x.y-TRIAL' );                                          # 53
is( gentooize_version( '1.67-TRIAL',  { lax => 1 } ), '1.670.0_rc',   'x.yy-TRIAL' );                                         # 54
is( gentooize_version( '1.675-TRIAL', { lax => 1 } ), '1.675.0_rc',   'x.yyy-TRIAL' );                                        # 55
is( gentooize_version( '1.6_01',      { lax => 1 } ), '1.601.0_rc',   'x.y_z' );                                              # 56
is( gentooize_version( '1.67_01',     { lax => 1 } ), '1.670.100_rc', 'x.yy_zz' );                                            # 57
is( gentooize_version( '1.675_01',    { lax => 1 } ), '1.675.10_rc',  'x.yyy_zz' );                                           # 58

isnt( $e = exception { gentooize_version( '1.6_01_01', { lax => 1 } ) }, undef, 'x.y_z_a fails' );                            # 59
is( gentooize_version( '1.6.A',       { lax => 2 } ), '1.6.10',             'x.y.ASCII' );                                    # 60
is( gentooize_version( '1.6.AA',      { lax => 2 } ), '1.6.370',            'x.y.ASCII' );                                    # 61
is( gentooize_version( '1.6.AAA',     { lax => 2 } ), '1.6.370.10',         'x.y.ASCII' );                                    # 62
is( gentooize_version( '1.6.AAAA',    { lax => 2 } ), '1.6.370.370',        'x.y.ASCII' );                                    # 63
is( gentooize_version( '1.6.A6FGHKE', { lax => 2 } ), '1.6.366.556.632.14', 'x.y.ASCII' );                                    # 64

is( gentooize_version('1.1000.10'), '1.1000.10', '4-digit-middle-bit' );
done_testing;
