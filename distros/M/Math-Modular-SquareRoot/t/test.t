use Test::More qw(no_plan);

use Math::Modular::SquareRoot qw(:all);

# gcd

ok 2 == gcd 2;
ok 2 == gcd qw(12 10 8 6 4);
ok 2 == gcd qw(12 10 -8 -6 4);
ok 3 == gcd 3*5*7*11*13*17*19, 3*3*23*29*31, 3*3*3*37*41*43*47;
ok 4 == gcd 8, 0, 12;

eval {gcd 'aa','bb'};
ok $@ =~ /aa not a number/;

eval {gcd 1.1, 2};
ok $@ =~ /1\.1 not an integer/;

eval {gcd '', 0, undef};
ok $@ =~ /  not a number/;


# gcd2

ok 2 == gcd2 12, 10;
ok 2 == gcd2 10, -8;
ok 3 == gcd2 3*5*7*11*13*17*19, gcd2 3*3*23*29*31, 3*3*3*37*41*43*47;

ok 1 == gcd2 1,1;
ok 1 == gcd2 0,1;

eval {gcd2 1,0};
ok $@ =~ /Illegal modulus zero/;

eval {gcd2 0,0};
ok $@ =~ /Illegal modulus zero/;

eval {gcd2 1,'aa'};
ok $@ =~ /Illegal modulus zero/;


# dgcd

ok "@{[-1,    1]}" eq  "@{[dgcd( 2,    3)]}";
ok "@{[-1,    3]}" eq  "@{[dgcd( 35,  12)]}";
ok "@{[-7,   24]}" eq  "@{[dgcd( 41,  12)]}";

ok "@{[-1,   -1]}" eq  "@{[dgcd( 2,   -3)]}";
ok "@{[-1,   -3]}" eq  "@{[dgcd( 35, -12)]}";
ok "@{[-7,  -24]}" eq  "@{[dgcd( 41, -12)]}";

ok "@{[ 1,    1]}" eq  "@{[dgcd(-2,    3)]}";
ok "@{[ 1,    3]}" eq  "@{[dgcd(-35,  12)]}";
ok "@{[ 7,   24]}" eq  "@{[dgcd(-41,  12)]}";

ok "@{[ 1,   -1]}" eq  "@{[dgcd(-2,  - 3)]}";
ok "@{[ 1,   -3]}" eq  "@{[dgcd(-35, -12)]}";
ok "@{[ 7,  -24]}" eq  "@{[dgcd(-41, -12)]}";

ok "@{[ 1,   -1]}" eq  "@{[dgcd( 3,    2)]}";
ok "@{[ 3,   -1]}" eq  "@{[dgcd( 12,  35)]}";
ok "@{[24,   -7]}" eq  "@{[dgcd( 12,  41)]}";

ok "@{[-2,   -7]}" eq  "@{[dgcd( 24,  -7)]}";

ok "@{[    1,    -100]}" eq  "@{[dgcd(1010101, 10101)]}";
ok "@{[20203, -224478]}" eq  "@{[dgcd(1010101, 90909)]}";


# msqrt1

ok "1 2"  eq "@{[msqrt1(4,3)]}";
ok "2 3"  eq "@{[msqrt1(4,5)]}";
ok "2 5"  eq "@{[msqrt1(4,7)]}";
ok "3 4"  eq "@{[msqrt1(2,7)]}";
ok "0"    eq "@{[msqrt1(0,11)]}";
ok "1 10" eq "@{[msqrt1(1,11)]}";
ok "2 9"  eq "@{[msqrt1(4,11)]}";
ok "3 8"  eq "@{[msqrt1(9,11)]}";
ok "4 7"  eq "@{[msqrt1(5,11)]}";
ok "5 6"  eq "@{[msqrt1(3,11)]}";

ok "0 6"      eq "@{[msqrt1(0,12)]}";
ok "1 5 7 11" eq "@{[msqrt1(1,12)]}";
ok "2 4 8 10" eq "@{[msqrt1(4,12)]}";
ok "3 9"      eq "@{[msqrt1(9,12)]}";


 {my ($a, $b) = (10902, 90109);
  ok "@{[$a,38545,51564,$b-$a]}" eq "@{[msqrt1($a*$a, $b)]}";
 } 


# prime

ok  prime(2);
ok  prime(3);
ok !prime(4);
ok  prime(5);
ok !prime(6);
ok  prime(7);
ok !prime(8);
ok !prime(9);
ok !prime(10);
ok  prime(11);
ok !prime(12);
ok  prime(13);
ok  prime(1_000_037);
ok  prime(1_000_039);


ok  prime(1_000_037);
ok  prime(1_000_039);
ok !prime(2_000_001);
ok !prime(814868468129, 6);
ok !prime(factorial( 6)+1);
ok !prime(factorial( 7)+1);
ok !prime(factorial( 8)+1);
ok !prime(factorial( 9)+1);
ok !prime(factorial(10)+1);

ok  prime(                         3*2-1);
ok  prime(                       5*3*2-1);
ok  prime(                     7*5*3*2+1);
ok  prime(                  11*7*5*3*2-1);
ok  prime(               13*11*7*5*3*2-1);
ok  prime(            17*13*11*7*5*3*2+19);
ok  prime(         19*17*13*11*7*5*3*2-23);
ok  prime(      23*19*17*13*11*7*5*3*2-79);
ok  prime(   29*23*19*17*13*11*7*5*3*2-73);
ok  prime(31*29*23*19*17*13*11*7*5*3*2+1);

ok  prime(2** 2 -1, 7);
ok  prime(2** 3 -1, 7);
ok  prime(2** 5 -1, 7);
ok  prime(2** 7 -1, 7);
ok  prime(2**11 +5, 7);
ok  prime(2**13-13, 7);
ok  prime(2**17 -1, 7);
ok  prime(2**19 -1, 7);
ok  prime(2**23-37, 7);
ok  prime(2**29 -3, 7);
ok  prime(2**31 -1, 7);
ok  prime(2**37+29, 7);
ok  prime(2**43+401, 7);


# dsqrt

 {my ($a, $b) = (1_000_037, 1_000_039);
  my $p       = $a*$b;       
  my $s = 243243;
  my $S = $s*$s%$p;
#print "@{[msqrt2($S,$a,$b)]}\n";
  ok "@{[qw(243243 243252243227 756823758219 1000075758200)]}" eq "@{[msqrt2($S,$a,$b)]}";
 } 

