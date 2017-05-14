# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FLAT-FA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 81;
use lib qw(../lib);
BEGIN { use_ok('FLAT::Legacy::FA') };
BEGIN { use_ok('FLAT::Legacy::FA::DFA') };
BEGIN { use_ok('FLAT::Legacy::FA::NFA') };
BEGIN { use_ok('FLAT::Legacy::FA::PFA') };
BEGIN { use_ok('FLAT::Legacy::FA::PRE') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $pre = FLAT::Legacy::FA::PRE->new();

$pre->set_pre("1*");
my @removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1*...");

$pre->set_pre("0&1*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 0&1*...");

$pre->set_pre("0|1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0|1...");

$pre->set_pre("10*1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 10*1...");

$pre->set_pre("1&1*00");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1&1*00...");

$pre->set_pre("111|1*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 111|1*...");

$pre->set_pre("1|1000|0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1|1000|0...");

$pre->set_pre("00&100&1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 8, "DFA_min for 00&100&1...");

$pre->set_pre("10&11*00");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 6, "DFA_min for 10&11*00...");

$pre->set_pre("1*1110&0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1*1110&0...");

$pre->set_pre("1*10&100*0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 3, "DFA_min for 1*10&100*0...");

$pre->set_pre("01110|00");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 01110|00...");

$pre->set_pre("0&1&10&10&01&0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 30, "DFA_min for 0&1&10&10&01&0...");

$pre->set_pre("0|10110|10");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0|10110|10...");

$pre->set_pre("001*1001|1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 001*1001|1...");

$pre->set_pre("0&000(11|0)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0&000(11|0)...");

$pre->set_pre("100&11|00");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 5, "DFA_min for 100&11|00...");

$pre->set_pre("00101*00*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 00101*00*...");

$pre->set_pre("0*11(11*0&1())");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 0*11(11*0&1())...");

$pre->set_pre("0110*00*1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0110*00*1...");

$pre->set_pre("00000*1|1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 00000*1|1...");

$pre->set_pre("1000|111");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1000|111...");

$pre->set_pre("1(100(1*00))");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1(100(1*00))...");

$pre->set_pre("01*11|010&1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 01*11|010&1...");

$pre->set_pre("0110*10(1)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0110*10(1)...");

$pre->set_pre("0&01|1100");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 3, "DFA_min for 0&01|1100...");

$pre->set_pre("10|10&10(0)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 10|10&10(0)...");

$pre->set_pre("1110|011");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1110|011...");

$pre->set_pre("00|0|1*100*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 00|0|1*100*...");

$pre->set_pre("1(101&011)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 1(101&011)...");

$pre->set_pre("0010001*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0010001*...");

$pre->set_pre("0&0|111|10");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 3, "DFA_min for 0&0|111|10...");

$pre->set_pre("00|00&110");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 00|00&110...");

$pre->set_pre("00|1110|1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 00|1110|1...");

$pre->set_pre("010011*1*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 010011*1*...");

$pre->set_pre("01&011(01)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 3, "DFA_min for 01&011(01)...");

$pre->set_pre("0111|0*1(1)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0111|0*1(1)...");

$pre->set_pre("01&100|10");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 01&100|10...");

$pre->set_pre("11000|00");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 11000|00...");

$pre->set_pre("11|0110(1*)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 11|0110(1*)...");

$pre->set_pre("1*01|010&0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1*01|010&0...");

$pre->set_pre("0&001&00|1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 0&001&00|1...");

$pre->set_pre("010&11(1|0)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 5, "DFA_min for 010&11(1|0)...");

$pre->set_pre("1*011010&0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 3, "DFA_min for 1*011010&0...");

$pre->set_pre("1&1&00101");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 1&1&00101...");

$pre->set_pre("0010|011");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0010|011...");

$pre->set_pre("1110001|0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1110001|0...");

$pre->set_pre("001101(0*)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 001101(0*)...");

$pre->set_pre("000|1*101");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 000|1*101...");

$pre->set_pre("11&01|000*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 5, "DFA_min for 11&01|000*...");

$pre->set_pre("0|01&1*110");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 0|01&1*110...");

$pre->set_pre("111001|0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 111001|0...");

$pre->set_pre("00&0&0010*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 10, "DFA_min for 00&0&0010*...");

$pre->set_pre("110*1011");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 110*1011...");

$pre->set_pre("0&1100|10");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 0&1100|10...");

$pre->set_pre("1*0|10011&0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 1*0|10011&0...");

$pre->set_pre("1|010&000");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 5, "DFA_min for 1|010&000...");

$pre->set_pre("1*00&10|10");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 5, "DFA_min for 1*00&10|10...");

$pre->set_pre("0001&0(10)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 0001&0(10)...");

$pre->set_pre("01&1&01|0&1");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 6, "DFA_min for 01&1&01|0&1...");

$pre->set_pre("0(0*0*1000)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0(0*0*1000)...");

$pre->set_pre("111*1&0*01");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 3, "DFA_min for 111*1&0*01...");

$pre->set_pre("00*0|010&1*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 7, "DFA_min for 00*0|010&1*...");

$pre->set_pre("011&1000");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 011&1000...");

$pre->set_pre("01100&00");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 01100&00...");

$pre->set_pre("1|0(00|011)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 1|0(00|011)...");

$pre->set_pre("10|0(1|11&0)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 10|0(1|11&0)...");

$pre->set_pre("10010&01()");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 10010&01()...");

$pre->set_pre("1010&11*0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 9, "DFA_min for 1010&11*0...");

$pre->set_pre("01001*00");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 01001*00...");

$pre->set_pre("1*00&10&01|0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 32, "DFA_min for 1*00&10&01|0...");

$pre->set_pre("1*00*1|00*0&0");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 1*00*1|00*0&0...");

$pre->set_pre("0000|0(10)");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 0000|0(10)...");

$pre->set_pre("010|10&01");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 010|10&01...");

$pre->set_pre("1000110*");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1000110*...");

$pre->set_pre("110*1111");
@removed = $pre->to_pfa()->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 110*1111...");

print "These tests were created using samples/make.tests.pl\n";
