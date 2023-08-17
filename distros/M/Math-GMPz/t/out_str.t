use warnings;
use strict;
use Math::GMPz qw(:mpz);

print "1..2\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $str = Math::GMPz->new('3579' x 6);
my $ok = '';

my $ret = Rmpz_out_str($str, 16);

if($ret == 20) {$ok .= 'a'}
else {print "\nReturned: ", $ret, "\n"}

print "\n";

$ret = Rmpz_out_str($str, 16, " \n");

if($ret == 20) {$ok .= 'b'}
else {print "Returned: ", $ret, "\n"}

$ret = Rmpz_out_str("hello world ", $str, 16);

if($ret == 20) {$ok .= 'c'}
else {print "Returned: ", $ret, "\n"}

print "\n";

$ret = Rmpz_out_str("hello world ", $str, 16, " \n");

if($ret == 20) {$ok .= 'd'}
else {print "Returned: ", $ret, "\n"}


if($ok eq 'abcd') {print "ok 1 \n"}
else {print "not ok 1 $ok\n"}

$ok = '';

eval{$ret = Rmpz_out_str($str);};
$ok .= 'a' if $@ =~ /Wrong number of arguments/;

eval{$ret = Rmpz_out_str($str, 16, 0, 7, 5);};
$ok .= 'b' if $@ =~ /Wrong number of arguments/;

if($ok eq 'ab') {print "ok 2 \n"}
else {print "not ok 2 $ok\n"}



