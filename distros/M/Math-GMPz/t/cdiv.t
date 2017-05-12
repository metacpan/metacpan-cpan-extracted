use strict;
use warnings;
use Math::GMPz qw(:mpz);

print "1..9\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my
 $n2 =  '1010101010101010000000000000000000000111111110001010';

my $x = Rmpz_init_set_str( $n2, 2);
my $z = Rmpz_init_set_str('24018831509027921', 10);
my $q = Rmpz_init();
my $r = Rmpz_init2(50);

my $ul = 1009;
my $ret;

Rmpz_cdiv_q($q, $z, $x);
if(Rmpz_get_str($q, 10) eq '9')
     {print "ok 1\n"}
else {print "not ok 1\n"}

Rmpz_cdiv_r($r, $z, $x);
if(Rmpz_get_str($r, 10) eq '-3002353938628489')
     {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpz_cdiv_qr($q, $r, $z, $x);
if(Rmpz_get_str($r, 10) eq '-3002353938628489'
   &&
   Rmpz_get_str($q, 10) eq '9')
     {print "ok 3\n"}
else {print "not ok 3\n"}


 $ret = Rmpz_cdiv_q_ui($q, $z, $ul);
if($ret == 356
   &&
   Rmpz_get_str($q, 10) eq '23804590197253')
     {print "ok 4\n"}
else {print "not ok 4\n"}

$ret = Rmpz_cdiv_r_ui($r, $z, $ul);

if($ret == 356
   &&
   Rmpz_get_str($r, 10) eq '-356')
     {print "ok 5\n"}
else {print "not ok 5\n"}

$ret = Rmpz_cdiv_qr_ui($q, $r, $z, $ul);
if($ret == 356
   &&
   Rmpz_get_str($r, 10) eq '-356'
   &&
   Rmpz_get_str($q, 10) eq '23804590197253')
     {print "ok 6\n"}
else {print "not ok 6\n"}

$ret = Rmpz_cdiv_ui($z, $ul);
if($ret == 356)
     {print "ok 7\n"}
else {print "not ok 7\n"}

Rmpz_cdiv_q_2exp($q, $z, 3);
if(Rmpz_get_str($q, 10) eq '3002353938628491')
     {print "ok 8\n"}
else {print "not ok 8\n"}

Rmpz_cdiv_r_2exp($r, $z, 3);
if(Rmpz_get_str($r, 10) eq '-7')
     {print "ok 9\n"}
else {print "not ok 9\n"}
