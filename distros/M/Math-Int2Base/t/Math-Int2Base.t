#!/usr/bin/perl -Tw

#---------------------------------------------------------------------
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-Int2Base.t'

# change 'tests => 1' to 'tests => last_test_to_print';
# use Test::More tests => 1;
use Test::More 'no_plan';

BEGIN { use_ok('Math::Int2Base') };

# Insert your test code below, the Test::More module is use()ed here so read 
# its man page ( perldoc Test::More ) for help writing this test script. 
#---------------------------------------------------------------------


{ # pod

  use Math::Int2Base qw( int2base base2int base_chars );

  my $base = 16;  # i.e., hexidecimal
  my $hex = int2base( 255,  $base );  # FF
  my $dec = base2int( $hex, $base );  # 255

  my $sixdig = int2base( 100, 36, 6  ); # 00002S
  my $decno  = base2int( $sixdig, 36 ); # 100, i.e., leading zeros no problem

  my $chars = base_chars( 24 );  # 0123...KLMN
  my $regex = qr/^[$chars]$/;    # used as character class

  use bigint;  # if needed
  my $googol = 10**100;
  my $base62 = int2base( $googol, 62 );  # QCyvrY2MJnQFGlUHTCA95Xz8AHOrLuoIO0fuPkHHCcyXy9ytM5N1lqsa
  my $bigint = base2int( $base62, 62 );  # back to 1e+100

  # from one base to another (via base-10)
  sub base_convert {
      my( $num, $from_base, $to_base ) = @_;
      return int2base( base2int( $num, $from_base ), $to_base );
  }

    is( $hex, 'FF', '255 to hex' );
    is( $dec,  255, 'FF hex to decimal' );

    is( $sixdig, '00002S', '100 to base-36' );
    is( $decno,       100, '00002S/base-36 to base-10' );

    is( $chars, '0123456789ABCDEFGHIJKLMN',              'base_chars( 24 )'   );

    is( $base62, 'QCyvrY2MJnQFGlUHTCA95Xz8AHOrLuoIO0fuPkHHCcyXy9ytM5N1lqsa', '10**100 to base-62' );
    is( $bigint, "1"."0"x100,                               '10**100 to base-62 back to base-10'  );
    isnt( $bigint, $googol+99,                              '10**100 to base-62 back to base-10'  );

    is( base_convert( "ZAQFG", 36, 16 ), int2base( 59287372, 16 ), 'base_convert() example' );

}

{ # base-62

    my $chars = base_chars( 62 );
    is( $chars,
        '0123456789'.
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
        'abcdefghijklmnopqrstuvwxyz',
        'base_chars( 62 )' );

    for ( 0 .. 61 ) {
        my $x = int2base( $_, 62 );
        is( $x, substr( $chars, $_, 1 ), "$x to base-62" );
    }

}

# binary
for ( 0 .. 16 ) {
    my $x = int2base( $_, 2 );
    is( $x, sprintf( "%b", $_ ), '$x to base-2' );
    is( $_, base2int( $x, 2 ),   'binary round trip: $x' );
}

# hex 
for ( 0 .. 16 ) {
    my $x = int2base( $_, 16 );
    is( $x, sprintf( "%X", $_ ), '$x to base-16' );
    is( $_, base2int( $x, 16 ),  'hex round trip: $x' );
}

# octal
for ( 0 .. 16 ) {
    my $x = int2base( $_, 8 );
    is( $x, sprintf( "%o", $_ ), '$x to base-16' );
    is( $_, base2int( $x, 8 ),   'octal round trip: $x' );
}

# minlen
for ( 1 .. 9 ) {
    my $x = int2base( 1, 2, $_ );
    is( $_, length $x,         'minlen == $_' );
    is( 1,  base2int( $x, 2 ), 'minlen round trip: $x' );
}

# non-integers  XXX[1] error or not?
for( 1.1, 1.5, 1.9 ) {
    my $x = int2base( $_, 2 );
    is( $x, 1, 'non-integers silently "inted"' );
}

# errors ...

# int2base

eval{ int2base( 1, 1 ) };
ok( $@ =~ /^not supported/,  'base < 2 not supported' );

eval{ int2base( 1, 63 ) };
ok( $@ =~ /^not supported/,  'base > 62 not supported' );

eval{ int2base( -1, 2 ) };
ok( $@ =~ /^not supported/,  'number < 0 not supported' );

eval{ int2base( 1, 2, -1 ) };
ok( $@ =~ /^not supported/,  'minlen < 0 not supported' );

#  XXX[1] do we care?
#  eval{ int2base( 1.9, 2 ) };
#  ok( $@ =~ /^not supported/,  'non-integer not supported' );


# base2int

eval{ base2int( 3, 2 ) };
ok( $@ =~ /^not supported/,  'number out of range not supported' );

eval{ base2int( 'ff', 16 ) };
ok( $@ =~ /^not supported/,  'lowercase hex not supported' );

eval{ base2int( 1, 1 ) };
ok( $@ =~ /^not supported/,  'base < 2 not supported' );

eval{ base2int( 1, 63 ) };
ok( $@ =~ /^not supported/,  'base > 62 not supported' );


