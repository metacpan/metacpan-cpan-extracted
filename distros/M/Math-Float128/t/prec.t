
use warnings;
use strict;
use Math::Float128 qw(:all);

my $tests = 7;
print "1..$tests\n";

my $tv = STRtoF128('-1e-37');

my $init_prec = 36;

warn "\nFYI:\n FLT128_DIG = ", FLT128_DIG,  "\n Default precision = ", flt128_get_prec(), "\n";

my $ok;

if(flt128_get_prec() == $init_prec) {$ok .= 'a'}
else {
  warn "\nDefault precision: ", flt128_get_prec(), "\n";
}

flt128_set_prec(18);

if(flt128_get_prec() == 18) {$ok .= 'b'}
else {
  warn "\nDefault precision: ", flt128_get_prec(), "\n";
}

if($ok eq 'ab') {print "ok 1\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 1\n";
}

my $man = (split /e/i, F128toSTR($tv))[0];

if($man eq '-1.00000000000000000') {print "ok 2\n"}
else {
  warn "\n2: Got: $man\n\$tv: $tv\n";
  print "not ok 2\n";
}


$man = (split /e/i, F128toSTRP($tv, 19))[0];

if($man eq '-1.000000000000000000') {print "ok 3\n"}
else {
  warn "\n3: Got: $man\nIF: \$tv: $tv\n";
  print "not ok 3\n";
}

flt128_set_prec(19);

if(flt128_get_prec() == 19) {print "ok 4\n"}
else {
  warn "\nDefault Precision: ", flt128_get_prec(), "\n";
  print "not ok 4\n";
}

$tv *= UnityF128(-1);

my $len = length((split /e/i, F128toSTR($tv))[0]);

if($len == 20) {print "ok 5\n"} # 19 digits plus decimal point
else {
  warn "\nMant: ", (split /e/i, F128toSTR($tv))[0], "\n\$tv: $tv\n";
  warn "Length: $len\n";
  print "not ok 5\n";
}

eval{flt128_set_prec(-2);};
if($@ =~ /1st arg/){print "ok 6\n"}
else {
  warn "\$\@: $@";
  print "not ok 6\n";
}

eval{F128toSTRP($tv, 0);};
if($@ =~ /2nd arg/){print "ok 7\n"}
else {
  warn "\$\@: $@";
  print "not ok 7\n";
}

