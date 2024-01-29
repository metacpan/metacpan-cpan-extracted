# Tests 2 & 3 fail if LDBL_DIG == 15

use warnings;
use strict;
use POSIX qw(ceil);
use Math::LongDouble qw(:all);

my $tests = 7;
print "1..$tests\n";

my $tv = STRtoLD('-1e-37');

my $p = Math::LongDouble::_LDBL_MANT_DIG()
           ? Math::LongDouble::_LDBL_MANT_DIG()
           :  Math::LongDouble::_DBL_MANT_DIG() ? Math::LongDouble::_DBL_MANT_DIG()
                                                : 64;

my $init_prec = 1 + ceil($p * log(2) / log(10));

warn "\nFYI:\n DBL_DIG = ", LD_DBL_DIG, "\n LDBL_DIG = ", LD_LDBL_DIG, "\n Default precison = $init_prec\n";

my $ok;

if(ld_get_prec() == $init_prec) {$ok .= 'a'}
else {
  warn "\nDefault precision: ", ld_get_prec(), "\n";
}

ld_set_prec(18);

if(ld_get_prec() == 18) {$ok .= 'b'}
else {
  warn "\nDefault precision: ", ld_get_prec(), "\n";
}

if($ok eq 'ab') {print "ok 1\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 1\n";
}

my $man = (split /e/i, LDtoSTR($tv))[0];

if(Math::LongDouble::_LDBL_DIG() >= 18) {
  if($man eq '-1.00000000000000000') {print "ok 2\n"}
  else {
    warn "\n2: Got: $man\n\$tv: $tv\n";
    print "not ok 2\n";
  }
}
else {
  warn "\n Skipping test 2 - LDBL_DIG is less than 18\n";
  print "ok 2\n";
}

$man = (split /e/i, LDtoSTRP($tv, 19))[0];

if(Math::LongDouble::_LDBL_DIG() == 18) {
  if($man eq '-9.999999999999999999') {print "ok 3\n"}
  else {
    warn "\n3: Got: $man\nIF: \$tv: $tv\n";
    print "not ok 3\n";
  }
}
elsif(Math::LongDouble::_LDBL_DIG() > 18) {
  if($man eq '-1.000000000000000000') {print "ok 3\n"}
  else {
    warn "\n3: Got: $man\nELSIF: \$tv: $tv\n";
    print "not ok 3\n";
  }
}
else {
  warn "\n Skipping test 3 - LDBL_DIG is less than 18\n";
  print "ok 3\n";
}


ld_set_prec(19);

if(ld_get_prec() == 19) {print "ok 4\n"}
else {
  warn "\nDefault Precision: ", ld_get_prec(), "\n";
  print "not ok 4\n";
}

$tv *= UnityLD(-1);

my $len = length((split /e/i, LDtoSTR($tv))[0]);

if($len == 20) {print "ok 5\n"} # 19 digits plus decimal point
else {
  warn "\nMant: ", (split /e/i, LDtoSTR($tv))[0], "\n\$tv: $tv\n";
  warn "Length: $len\n";
  print "not ok 5\n";
}

eval{ld_set_prec(-2);};
if($@ =~ /1st arg/){print "ok 6\n"}
else {
  warn "\$\@: $@";
  print "not ok 6\n";
}

eval{LDtoSTRP($tv, 0);};
if($@ =~ /2nd arg/){print "ok 7\n"}
else {
  warn "\$\@: $@";
  print "not ok 7\n";
}

