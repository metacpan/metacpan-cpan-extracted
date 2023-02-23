use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..2\n";

my $ok = '';

Rmpc_set_default_rounding_mode(MPC_RNDNN);
if(Rmpc_get_default_rounding_mode == 0) {$ok = 'a'}
Rmpc_set_default_rounding_mode(MPC_RNDZN);
if(Rmpc_get_default_rounding_mode == 1) {$ok .= 'b'}
Rmpc_set_default_rounding_mode(MPC_RNDUN);
if(Rmpc_get_default_rounding_mode == 2) {$ok .= 'c'}
Rmpc_set_default_rounding_mode(MPC_RNDDN);
if(Rmpc_get_default_rounding_mode == 3) {$ok .= 'd'}
Rmpc_set_default_rounding_mode(MPC_RNDNZ);
if(Rmpc_get_default_rounding_mode == 16) {$ok .= 'e'}
Rmpc_set_default_rounding_mode(MPC_RNDZZ);
if(Rmpc_get_default_rounding_mode == 17) {$ok .= 'f'}
Rmpc_set_default_rounding_mode(MPC_RNDUZ);
if(Rmpc_get_default_rounding_mode == 18) {$ok .= 'g'}
Rmpc_set_default_rounding_mode(MPC_RNDDZ);
if(Rmpc_get_default_rounding_mode == 19) {$ok .= 'h'}
Rmpc_set_default_rounding_mode(MPC_RNDNU);
if(Rmpc_get_default_rounding_mode == 32) {$ok .= 'i'}
Rmpc_set_default_rounding_mode(MPC_RNDZU);
if(Rmpc_get_default_rounding_mode == 33) {$ok .= 'j'}
Rmpc_set_default_rounding_mode(MPC_RNDUU);
if(Rmpc_get_default_rounding_mode == 34) {$ok .= 'k'}
Rmpc_set_default_rounding_mode(MPC_RNDDU);
if(Rmpc_get_default_rounding_mode == 35) {$ok .= 'l'}
Rmpc_set_default_rounding_mode(MPC_RNDND);
if(Rmpc_get_default_rounding_mode == 48) {$ok .= 'm'}
Rmpc_set_default_rounding_mode(MPC_RNDZD);
if(Rmpc_get_default_rounding_mode == 49) {$ok .= 'n'}
Rmpc_set_default_rounding_mode(MPC_RNDUD);
if(Rmpc_get_default_rounding_mode == 50) {$ok .= 'o'}
Rmpc_set_default_rounding_mode(MPC_RNDDD);
if(Rmpc_get_default_rounding_mode == 51) {$ok .= 'p'}

if($ok eq 'abcdefghijklmnop') {print "ok 1\n"}
else {print "not ok 1 $ok \n"}

$ok = '';

$ok .= 'a' if GMP_RNDN == (MPC_RNDNN & 3);
$ok .= 'b' if GMP_RNDZ == (MPC_RNDZN & 3);
$ok .= 'c' if GMP_RNDU == (MPC_RNDUN & 3);
$ok .= 'd' if GMP_RNDD == (MPC_RNDDN & 3);
$ok .= 'e' if GMP_RNDN == (MPC_RNDNZ & 3);
$ok .= 'f' if GMP_RNDZ == (MPC_RNDZZ & 3);
$ok .= 'g' if GMP_RNDU == (MPC_RNDUZ & 3);
$ok .= 'h' if GMP_RNDD == (MPC_RNDDZ & 3);
$ok .= 'i' if GMP_RNDN == (MPC_RNDNU & 3);
$ok .= 'j' if GMP_RNDZ == (MPC_RNDZU & 3);
$ok .= 'k' if GMP_RNDU == (MPC_RNDUU & 3);
$ok .= 'l' if GMP_RNDD == (MPC_RNDDU & 3);
$ok .= 'm' if GMP_RNDN == (MPC_RNDND & 3);
$ok .= 'n' if GMP_RNDZ == (MPC_RNDZD & 3);
$ok .= 'o' if GMP_RNDU == (MPC_RNDUD & 3);
$ok .= 'p' if GMP_RNDD == (MPC_RNDDD & 3);

$ok .= 'q' if GMP_RNDN == int(MPC_RNDNN / 16);
$ok .= 'r' if GMP_RNDN == int(MPC_RNDZN / 16);
$ok .= 's' if GMP_RNDN == int(MPC_RNDUN / 16);
$ok .= 't' if GMP_RNDN == int(MPC_RNDDN / 16);
$ok .= 'u' if GMP_RNDZ == int(MPC_RNDNZ / 16);
$ok .= 'v' if GMP_RNDZ == int(MPC_RNDZZ / 16);
$ok .= 'w' if GMP_RNDZ == int(MPC_RNDUZ / 16);
$ok .= 'x' if GMP_RNDZ == int(MPC_RNDDZ / 16);
$ok .= 'y' if GMP_RNDU == int(MPC_RNDNU / 16);
$ok .= 'z' if GMP_RNDU == int(MPC_RNDZU / 16);
$ok .= 'A' if GMP_RNDU == int(MPC_RNDUU / 16);
$ok .= 'B' if GMP_RNDU == int(MPC_RNDDU / 16);
$ok .= 'C' if GMP_RNDD == int(MPC_RNDND / 16);
$ok .= 'D' if GMP_RNDD == int(MPC_RNDZD / 16);
$ok .= 'E' if GMP_RNDD == int(MPC_RNDUD / 16);
$ok .= 'F' if GMP_RNDD == int(MPC_RNDDD / 16);

$ok .= 'G' if GMP_RNDN == (GMP_RNDN & 3);
$ok .= 'H' if GMP_RNDZ == (GMP_RNDZ & 3);
$ok .= 'I' if GMP_RNDU == (GMP_RNDU & 3);
$ok .= 'J' if GMP_RNDD == (GMP_RNDD & 3);

if($ok eq 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJ') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}
__END__
N => 0
Z => 1
U => 2
D => 3

0,1,2,3 => 0
16,17,18,19 => 1
32,33,34,35 => 2
48,49,50,51 => 3

RE => RND & 3
IM => int(RND / 16)

MPC_RNDNN => 0;
MPC_RNDZN => 1;
MPC_RNDUN => 2;
MPC_RNDDN => 3;

MPC_RNDNZ => 16;
MPC_RNDZZ => 17;
MPC_RNDUZ => 18;
MPC_RNDDZ => 19;

MPC_RNDNU => 32;
MPC_RNDZU => 33;
MPC_RNDUU => 34;
MPC_RNDDU => 35;

MPC_RNDND => 48;
MPC_RNDZD => 49;
MPC_RNDUD => 50;
MPC_RNDDD => 51;
