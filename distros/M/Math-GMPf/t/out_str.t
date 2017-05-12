use warnings;
use strict;
use Math::GMPf qw(:mpf);

print "1..2\n";

print "# Using gmp version ", Math::GMPf::gmp_v(), "\n";

Rmpf_set_default_prec(100);

my $str = Math::GMPf->new('3579' x 6);
my $ok = '';

my $ret = Rmpf_out_str($str, 16, 0);

if($ret == 25) {$ok .= 'a'}
else {print "\nReturned: ", $ret, "\n"}

print "\n";

$ret = Rmpf_out_str($str, 16, 0, " \n");

if($ret == 25) {$ok .= 'b'}
else {print "Returned: ", $ret, "\n"}

$ret = Rmpf_out_str("hello world ", $str, 16, 0);

if($ret == 25) {$ok .= 'c'}
else {print "Returned: ", $ret, "\n"}

print "\n";

$ret = Rmpf_out_str("hello world ", $str, 16, 0, " \n");

if($ret == 25) {$ok .= 'd'}
else {print "Returned: ", $ret, "\n"}

if($ok eq 'abcd') {print "ok 1 \n"}
else {print "not ok 1 $ok\n"}

$ok = '';

eval{$ret = Rmpf_out_str($str, 16);};
$ok .= 'a' if $@ =~ /Wrong number of arguments/;

eval{$ret = Rmpf_out_str($str, 16, 0, 7, 5, 6);};
$ok .= 'b' if $@ =~ /Wrong number of arguments/;

if($ok eq 'ab') {print "ok 2 \n"}
else {print "not ok 2 $ok\n"}



