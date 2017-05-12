use warnings;
use strict;
use Math::MPC qw(:mpc);

# mpc_out_str() segfaults on some architectures -
# better to use c_string() - or r_string() and i_string()

print "1..2\n";

Rmpc_set_default_prec2(100, 100);

my $string = Math::MPC->new('246' x 7, '3579' x 6);
my $ok = '';

my $ret = TRmpc_out_str(*STDOUT, 16, 0, $string, MPC_RNDNN);
# prints "(d.595a684adcdfe766000000000@16 4.bcbbcfdfb50863475ab000000@19)".

if($ret == 63) {$ok .= 'a'}
else {print "\nReturned: ", $ret, "\n"}

print "\n";

$ret = TRmpc_out_str(*STDOUT, 16, 0, $string, MPC_RNDNN, " \n");

if($ret == 63) {$ok .= 'b'}
else {print "Returned: ", $ret, "\n"}

$ret = TRmpc_out_str("hello world ", *STDOUT, 16, 0, $string, MPC_RNDNN);

if($ret == 63) {$ok .= 'c'}
else {print "Returned: ", $ret, "\n"}

print "\n";

$ret = TRmpc_out_str("hello world ", *STDOUT, 16, 0, $string, MPC_RNDNN, " \n");

if($ret == 63) {$ok .= 'd'}
else {print "Returned: ", $ret, "\n"}

if($ok eq 'abcd') {print "ok 1 \n"}
else {print "not ok 1 $ok\n"}

$ok = '';

eval{$ret = TRmpc_out_str($string, 16, 0, 1);};
$ok .= 'a' if $@ =~ /Wrong number of arguments/;

eval{$ret = TRmpc_out_str($string, 16, 0, MPC_RNDNN, 7, 5, 9, 10);};
$ok .= 'b' if $@ =~ /Wrong number of arguments/;

if($ok eq 'ab') {print "ok 2 \n"}
else {print "not ok 2 $ok\n"}



