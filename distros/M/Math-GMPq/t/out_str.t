use warnings;
use strict;
use Math::GMPq qw(:mpq);

print "1..2\n";

print "# Using gmp version ", Math::GMPq::gmp_v(), "\n";

my $str = Math::GMPq->new('3579' x 6 . '/' . '123' x 7);
my $ok = '';

my $ret = Rmpq_out_str($str, 16);

if($ret == 38) {$ok .= 'a'}
else {print "\nReturned: ", $ret, "\n"}

print "\n";

$ret = Rmpq_out_str($str, 16, " \n");

if($ret == 38) {$ok .= 'b'}
else {print "Returned: ", $ret, "\n"}

$ret = Rmpq_out_str("hello world ", $str, 16);

if($ret == 38) {$ok .= 'c'}
else {print "Returned: ", $ret, "\n"}

print "\n";

$ret = Rmpq_out_str("hello world ", $str, 16, " \n");

if($ret == 38) {$ok .= 'd'}
else {print "Returned: ", $ret, "\n"}

if($ok eq 'abcd') {print "ok 1 \n"}
else {print "not ok 1 $ok\n"}

$ok = '';

eval{$ret = Rmpq_out_str($str);};
$ok .= 'a' if $@ =~ /Wrong number of arguments/;

eval{$ret = Rmpq_out_str($str, 16, 0, 7, 10);};
$ok .= 'b' if $@ =~ /Wrong number of arguments/;

if($ok eq 'ab') {print "ok 2 \n"}
else {print "not ok 2 $ok\n"}



