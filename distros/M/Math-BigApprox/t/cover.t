BEGIN { $^W= 1; }
use strict;

use Test qw( plan ok );

plan(
    tests => 190,
    todo => [170],
);

my $fmt= "F";
sub NV
{
    return unpack $fmt, pack $fmt, shift @_;
}
$fmt= "d"
    if  NV(0.1) ne 0.1; # This perl must predate "F"
ok( NV(0.1),    0.1,    'NV(0.1) eq 0.1' );                               #1#

require Math::BigApprox;
ok(1);                                                                    #2#

Math::BigApprox->import( qw( c Prod Fact $SigDigs ) );
ok(1);                                                                    #3#
eval 'print STDERR "# Note:  SigDigs == $SigDigs\n";';

my %n;
for(
    0,                                                                    #4#
    0.5,                                                                  #5#
    1,                                                                    #6#
    1.25,                                                                 #7#
    2,                                                                    #8#
    2.5,                                                                  #9#
    5,                                                                    #10#
    52,                                                                   #11#
    -1,                                                                   #12#
    -0.1,                                                                 #13#
    -1234,                                                                #14#
    1e+100,                                                               #15#
    -1e-100,                                                              #16#
    1.05e-100,                                                            #17#
) {
    $n{$_}= Math::BigApprox->new( $_ );
    ok( $n{$_}, $_, "new $_" );
}
$n{"1e+400"}= $n{1e+100}**4;
ok( $n{"1e+400"},               "1e+400",       '1e+100**4 eq 1e+400' );  #18#

# Multiplication
ok( $n{0}*$n{1},                0,              'zero*one eq 0' );        #19#
ok( $n{1}*$n{2},                2,              'one*two eq 2' );         #20#
ok( $n{52}*$n{5},               52*5,           'cards*five eq 260' );    #21#
ok( $n{-1}*$n{0},               0,              'neg*zero eq 0' );        #22#
ok( $n{-1}*$n{-1},              1,              'neg*neg eq 1' );         #23#
ok( $n{5}*$n{-1234},            -5*1234,        'five*n234 eq -6170' );   #24#
ok( $n{1.25}*2,                 $n{2.5},        'quart*2 eq half' );      #25#
ok( 1.25*$n{2}*2,               5,              '1.25*two*2 eq 5' );      #26#
ok( $n{1e+100}*$n{-1e-100},     -1,             'big*tiny eq -1' );       #27#
ok( $n{1e+100}*$n{1e+100},      1e+200,         'big*big eq 1e200' );     #28#
ok( $n{1e+100}*1e+300,          "1e+400",       'big*1e300 eq 1e400' );   #29#
ok( 6*$n{1.05e-100},            6*1.05e-100,    '6*tq eq 6*1.05e-100' );  #30#
ok( $n{'1e+400'}*$n{'1e+400'},  "1e+800",       'huge*huge eq 1e+800' );  #31#

# Division
ok( $n{0}/$n{1},                0,              'zero/one eq 0' );        #32#
ok( $n{-1234}/$n{1},            -1234,          'n1234/one eq -1234' );   #33#
ok( $n{-1234}/$n{-1},           1234,           'n1234/neg eq 1234' );    #34#
ok( $n{52}/$n{-1},              -52,            'cards/neg eq -52' );     #35#
ok( $n{5}/2/$n{2},              $n{1.25},       'five/2/two eq quart' );  #36#
ok( -5/$n{2},                   -2.5,           '-5/two eq -2.5' );       #37#
ok( eval { 5/$n{0} },           undef,          "5/zero dies" );          #38#
ok( $n{1e+100}/$n{1e+100},      1,              'big/big eq 1' );         #39#
ok( $n{1e+100}/$n{-1e-100},     -1e+200,        'big/tiny eq -1e200' );   #40#
ok( $n{1e+100}/1e-300,          "1e+400",       'big/1e-300 eq 1e400' );  #41#
ok( $n{-1e-100}/1e+300,         "-1e-400",      'tiny/1e300 eq -1e-400' );#42#
ok( $n{1.05e-100}/5,            1.05e-100/5,    'tq/5 eq 1.05e-100/5' );  #43#

# Addition
ok( $n{0}+$n{52},               52,             'zero+cards eq 52' );     #44#
ok( $n{52}+0,                   52,             'cards+0 eq 52' );        #45#
ok( $n{52}+$n{1},               53,             'cards+one eq 53' );      #46#
ok( 0.52+$n{52},                52.52,          '0.52+cards eq 52.52' );  #47#
ok( $n{1e+100}+$n{-1e-100},     1e+100,         'big+tiny eq 1e100' );    #48#
ok( $n{1e+100}+$n{1e+100},      2e+100,         'big*big eq 2e100' );     #49#
ok( $n{1e+100}+1e+300,          1e+300,         'big+1e+300 eq 1e300' );  #50#
ok( 19+$n{-1e-100},             19,             '19+tiny eq 19' );        #51#
ok( $n{1.05e-100}+$n{-1e-100},  5e-102,         'qt+tiny eq 5e-102' );    #52#

# Subtraction
ok( $n{0}-$n{-1234},            1234,           'zero-n1234 eq 1234' );   #53#
ok( $n{1.05e-100}-1e-100,       5e-102,         'qt-1e-100 eq 5e-102' );  #54#
ok( -1234-$n{-1234},            0,              '-1234-n1234 eq 0' );     #55#
ok( $n{1.05e-100}-1.05e-100,    0,              'qt-1.05e-100 eq 0' );    #56#

# Negation
ok( -$n{0},                     0,              '-zero eq 0' );           #57#
ok( -$n{-1234},                 1234,           '-n1234 eq 1234' );       #58#
ok( -$n{1e+100},                -1e+100,        '-big eq -1e+100' );      #59#

# Exponentiation
ok( $n{0}**0,               1,              'zero**0 eq 1' );             #60#
ok( 0**$n{0},               1,              '0**zero eq 1' );             #61#
ok( 0**$n{-1234},           0,              '0**x eq 0' );                #62#
ok( $n{0}**-12.67,          0,              'zero**-12.67 eq 0' );        #63#
ok( $n{1}**$n{1e+100},      1,              '1**1e+100 eq 1' );           #64#
ok( $n{'1e+400'}**-1234,    '1e-493600',    'huge**-1234 eq 1e-493600' ); #65#
ok( $n{'1e+400'}**1e10, "1e+4000000000000", 'huge**1e10 eq 1e+4e12' );    #66#
ok( $n{'1e+400'}**1e100,    "1e+4e+102",    'huge**1e100 eq 1e4e102' );   #67#
ok( $n{'1e+400'}**1e300,    "1e+4e+302",    'huge**1e100 eq 1e4e302' );   #68#
ok( $n{-1}**0,              1,              'neg**1 eq 1' );              #69#
ok( $n{-1}**1,              -1,             'neg**1 eq -1' );             #70#
ok( $n{-1}**2,              1,              'neg**2 eq 1' );              #71#
ok( $n{-1}**3,              -1,             'neg**3 eq -1' );             #72#
ok( $n{-1}**-1,             1,              'neg**-1 eq 1' );             #73#
ok( $n{-1}**1e100,          1,              'neg**1e100 eq 1' );          #74#
ok( $n{-1234}**11,          c(-(1234**11)), 'n1234**11 eq -(1234**11)' ); #75#

# max exponent is likely 7.80728208626062e+307,
# aka 1.79769313486231574e308/log(10)
ok( $n{'1e+400'}**1e305,    "1e+4e+307",    'huge**1e305 eq 1e4e307' );   #76#

# abs() only because of buggy Perl environments where exp(1e300) is -inf:
my $inf= abs( exp(1e300) );

# This would fail on a system with bigger-than-typical "double" data type:
#ok($n{'1e+400'}**2e305,    $inf,           'huge**2e305 eq inf' );

ok( ($n{'1e+400'}**1e300)**1e300, $inf,     'huge**1e300**1e300 eq inf' );#77#

my $notzero= $n{-1e-100}**9e305;
ok( $notzero,           0,                  'tiny**9e305 eq 0' );         #78#
# TBD:  Perhaps $notzero should be a real zero?
# Or perhaps 1/0 should always return infinity rather than dying?
ok( 1/$notzero,         $inf,               '1/notzero eq inf' );         #79#
ok( 1/-$notzero,        -$inf,              '1/notzero eq -inf' );        #80#

# Product of sequence
my $deals= 48^$n{52};
ok( $deals,             48*49*50*51*52,     '48^cards eq 48*..*52' );     #81#
ok( Prod(48,52),        $deals,             'Prod(48,52) eq deals' );     #82#
ok( $n{52}^$n{5},       1,                  'cards^five eq 1' );          #83#
ok( Prod(52,5),         1,                  'Prod(52,5) eq 1' );          #84#

# Factorial
ok( !$n{-1},            1,                  '!neg eq 1' );                #85#
ok( !$n{0},             1,                  '!zero eq 1' );               #86#
ok( !$n{1},             1,                  '!one eq 1' );                #87#
ok( !$n{2},             2,                  '!two eq 2' );                #88#
ok( !$n{5},             120,                '!five eq 120' );             #89#
ok( Fact(-1),           1,                  '!neg eq 1' );                #90#
ok( Fact(0),            1,                  '!zero eq 1' );               #91#
ok( Fact(1),            1,                  '!one eq 1' );                #92#
ok( Fact(2),            2,                  '!two eq 2' );                #93#
ok( Fact(5),            120,                '!five eq 120' );             #94#
ok( !$n{52},        '/^8\.0658\d*e\+67$/',  '!cards =~ 8.0658..e+67' );   #95#
my $fact= !-$n{-1234};
ok( $fact,          '/^5.108\d*e\+3280$/',  '!-n1234 eq 5.108..e+3280' ); #96#
ok( Fact(1234),         $fact,              '!1234 eq !-n1234' );         #97#

# Shift
ok( $n{0}<<30,          0,                  'zero<<30 eq 0' );            #98#
ok( $n{0}>>30,          0,                  'zero>>30 eq 0' );            #99#
ok( $n{-1234}>>11,      '/^-0\.60\d*$/',    'n1234>>11 =~ -0.60...' );    #100#
ok( $n{-1234}<<2,       -4936,              'n1234<<2 eq -4936' );        #101#
ok( $n{1}<<30,          1<<30,              'one<<30 eq 1<<30' );         #102#
ok( $n{5}>>2,           $n{1.25},           'five>>2 eq quart' );         #103#
ok( 16<<$n{52},         '/^7\.2\d*e\+16$/', '16<<cards =~ 7.2...e+16' );  #104#
ok( $n{1}<<0.5,         c(sqrt(2)),         'one<<.5 eq sqrt 2' );        #105#
ok( $n{2}>>1.5,         c(sqrt(0.5)),       'two>>.5 eq sqrt .5' );       #106#

# Comparison
ok( $n{-1} < $n{0},         1,              'neg < zero' );               #107#
ok( $n{0} < $n{5},          1,              'zero < five' );              #108#
ok( $n{2} < 5,              1,              'two < 5' );                  #109#
ok( -$n{5} < $n{-1},        1,              '-five < neg' );              #110#
ok( $n{-1} >= $n{0},        !1,             'not neg >= zero' );          #111#
ok( $n{0} >= $n{5},         !1,             'not zero >= five' );         #112#
ok( 2 >= $n{5},             !1,             'not 2 >= five' );            #113#
ok( -$n{5} >= $n{-1},       !1,             'not -five >= neg' );         #114#

ok( $n{-1} <= $n{0},        1,              'neg <= zero' );              #115#
ok( $n{0} <= $n{5},         1,              'zero <= five' );             #116#
ok( $n{2} <= 5,             1,              'two <= 5' );                 #117#
ok( -$n{5} <= $n{-1},       1,              '-five <= neg' );             #118#
ok( $n{-1} > $n{0},         !1,             'not neg > zero' );           #119#
ok( $n{0} > $n{5},          !1,             'not zero > five' );          #120#
ok( 2 > $n{5},              !1,             'not 2 > five' );             #121#
ok( -$n{5} > $n{-1},        !1,             'not -five > neg' );          #122#

ok( $n{0} == 0,             1,              'zero == 0' );                #123#
ok( 1 == $n{1},             1,              '1 == one' );                 #124#
ok( -1 == $n{-1},           1,              '-1 == neg' );                #125#
ok( $n{0} < 0,              !1,             'not zero < 0' );             #126#
ok( 1 < $n{1},              !1,             'not 1 < one' );              #127#
ok( -1 < $n{-1},            !1,             'not -1 < neg' );             #128#
ok( $n{0} > 0,              !1,             'not zero > 0' );             #129#
ok( 1 > $n{1},              !1,             'not 1 > one' );              #130#
ok( -1 > $n{-1},            !1,             'not -1 > neg' );             #131#

ok( $notzero == 0,          1,              'notzero == 0' );             #132#
ok( $notzero <= 0,          1,              'notzero <= 0' );             #133#
ok( $notzero >= 0,          1,              'notzero >= 0' );             #134#
ok( $notzero < 0,           !1,             'not notzero < 0' );          #135#
ok( $notzero > 0,           !1,             'not notzero > 0' );          #136#

# Numification
ok( 0|$n{0},                0,              '0|zero eq 0' );              #137#
ok( 0|$n{-1},               0|-1,           '0|neg eq 0|-1' );            #138#
ok( 0|$n{52},               52,             '0|cards eq 52' );            #139#
ok( NV($n{0}),              0,              'NV zero eq 0' );             #140#
ok( NV($n{-1}),             -1,             'NV neg eq -1' );             #141#
ok( NV($n{52}),             52,             'NV cards eq 52' );           #142#
ok( NV($n{-0.1}),           -0.1,           'NV tenth eq -0.1' );         #143#
ok( NV($n{-1234}),          -1234,          'NV n1234 eq -1234' );        #144#
ok( NV($n{1e+100}**100),    $inf,           'NV big**100 eq inf' );       #145#
ok( NV($n{-1e-100}**100),   0,              'NV tiny**100 eq 0' );        #146#
ok( NV(1/$n{-1e-100}**101), -$inf,          'NV tiny**-100 eq -inf' );    #147#

# Stringification (covered in previous cases)

# Auto cloning
my $count= $n{0};
$count += 1;
ok( $count,                 1,              '++zero eq 1' );              #148#
ok( $n{0},                  0,              'zero++ eq 0' );              #149#

# abs()
ok( abs($n{0}),             0,              'abs zero eq 0' );            #150#
ok( abs($n{-1234}),         1234,           'abs n1234 eq 1234' );        #151#
ok( abs($n{'1e+400'}),      '1e+400',       'abs huge eq 1e+400' );       #152#
ok( abs(-$n{'1e+400'}),     '1e+400',       'abs -huge eq 1e+400' );      #153#

# log()
ok( eval { log($n{0}) },    undef,          'log zero dies' );            #154#
ok( eval { log($n{-1}) },   undef,          'log neg dies' );             #155#
ok( log($n{52}),            log(52),        'log cards == log 52' );      #156#

# sqrt()
ok( sqrt($n{0}),            0,              'sqrt zero == 0' );           #157#
ok( sqrt($n{1}),            1,              'sqrt one == 1' );            #158#
ok( eval { sqrt($n{-1}) },  undef,          'sqrt neg dies' );            #159#
ok( c(sqrt($n{52})),        c(sqrt(52)),    'c sqrt cards == c sqrt 52' );#160#

# bool
ok( eval { 1 if $n{0}; 1 }, undef,          'if zero dies' );             #161#

# Fall-back functions: (atan2, cos, sin, exp, and int)
ok( cos($n{0}),                 1,          'cos zero eq 1' );            #162#
ok( sin($n{0}),                 0,          'sin zero eq 0' );            #163#
ok( sin(atan2($n{1},$n{0})),    1,          'sin atan2(one,zero) eq 1' ); #164#
ok( c(exp($n{52})),             c(exp(52)), 'c exp cards eq c exp 52' );  #165#
ok( int($n{1.25}),              1,          'int quart eq 1' );           #166#

# Sign
ok( $n{0}->Sign(),              0,          'Sign zero eq 0' );           #167#
ok( $n{5}->Sign(),              1,          'Sign five eq 1' );           #168#
ok( $n{-1234}->Sign(),          -1,         'Sign n1234 eq -1' );         #169#
# To-do!
ok( $notzero->Sign(),           0,          'Sign notzero eq 0' );        #170#

++$count;
ok( $count->Sign(-9),           1,          'count->Sign(-9) eq 1' );     #171#
ok( $count->Sign(),             -1,         'Sign count eq -1' );         #172#
ok( $count,                     -2,         'count eq -1' );              #173#
ok( $count->Sign(19),           -1,         'count->Sign(19) eq -1' );    #174#
ok( $count->Sign(),             1,          'Sign count eq -1' );         #175#
ok( $count,                     2,          'count eq -1' );              #176#
ok( $count->Sign(0),            1,          'count->Sign(0) eq 1' );      #177#
ok( $count->Sign(),             0,          'Sign count eq 0' );          #178#
ok( $count,                     0,          'count eq 0' );               #179#

# Get
ok( $n{0}->Get(),               0,          'Get zero eq 0' );            #180#
ok( $n{1}->Get(),               0,          'Get one eq 0' );             #181#
ok( $n{5}->Get(),               log(5),     'Get 5 eq log(5)' );          #182#
ok( $n{-1234}->Get(),           log(1234),  'Get n1234 eq log(1234)' );   #183#
ok( $n{-1e-100}->Get(),         log(1e-100),'Get tiny eq log(1e-100)' );  #184#
ok( ( $n{5}->Get() )[0],        log(5),     '(Get 5)[0] eq log(5)' );     #185#
ok( ( $n{0}->Get() )[1],        0,          '(Get zero)[1] eq 0' );       #186#
ok( ( $n{5}->Get() )[1],        1,          '(Get five)[1] eq 1' );       #187#
ok( ( $n{-1234}->Get() )[1],    -1,         '(Get n1234)[1] eq -1' );     #188#
ok( @{[ $n{2}->Get() ]},        2,          '@(Get 2) eq 2' );            #189#

# croaks
ok( eval { c(); 1 },            undef,      "Empty c'tor dies" );         #190#

__END__

# This code fixes up test numbers above.
# Use:  perl -x t/cover.t
#!/usr/bin/perl -i.tmp -p
BEGIN { @ARGV= $0 }

s/(?<=#)(\d+)(?=#)/
    !$test ? ( $test= $1 ) : ++$test
/ge;
