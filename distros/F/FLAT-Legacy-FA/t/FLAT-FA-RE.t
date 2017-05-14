# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FLAT-FA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 48;
use lib qw(../lib);
BEGIN { use_ok('FLAT::Legacy::FA') };
BEGIN { use_ok('FLAT::Legacy::FA::DFA') };
BEGIN { use_ok('FLAT::Legacy::FA::NFA') };
BEGIN { use_ok('FLAT::Legacy::FA::PFA') };
BEGIN { use_ok('FLAT::Legacy::FA::RE') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $re = FLAT::Legacy::FA::RE->new();


print "These tests were created using samples/make.tests.pl\n";

$re->set_re("1*");
my @removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1*...");

$re->set_re("1|0");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1|0...");

$re->set_re("0*0|0");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0*0|0...");

$re->set_re("00*0*1*");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 00*0*1*...");

$re->set_re("000|1");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 000|1...");

$re->set_re("100*1*");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 100*1*...");

$re->set_re("10*11");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 10*11...");

$re->set_re("1110*11*10");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1110*11*10...");

$re->set_re("0010*1001*");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 0010*1001*...");

$re->set_re("111011*01");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 111011*01...");

$re->set_re("00|1*0|0010");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 00|1*0|0010...");

$re->set_re("01001|11(1|)");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 01001|11(1|)...");

$re->set_re("11*0*110|00*");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 11*0*110|00*...");

$re->set_re("0*11*1100*0");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0*11*1100*0...");

$re->set_re("101*11|1*0*1");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 101*11|1*0*1...");

$re->set_re("10|0*1100*1101|1100|0");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 10|0*1100*1101|1100|0...");

$re->set_re("0100|100001001|0|1|0");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 0100|100001001|0|1|0...");

$re->set_re("01001|10101001111");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 01001|10101001111...");

$re->set_re("1*1*000|1011110*1011");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 1*1*000|1011110*1011...");

$re->set_re("100100*0|011*11(1*0)0|0");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 100100*0|011*11(1*0)0|0...");

$re->set_re("11011(10*11|0100011*)");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 11011(10*11|0100011*)...");

$re->set_re("1*0*011|0|1101110|111");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 1*0*011|0|1101110|111...");

$re->set_re("1(101|1001|0|1000|111)");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 1(101|1001|0|1000|111)...");

$re->set_re("11011*0110101110001000|000100*10100");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 5, "DFA_min for 11011*0110101110001000|000100*10100...");

$re->set_re("01(11*11*0*01|1*1|0)010101010|000001|11100|1");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 5, "DFA_min for 01(11*11*0*01|1*1|0)010101010|000001|11100|1...");

$re->set_re("10(0*00*0)10001(10*01101100)00*0*11(1)10100");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 1, "DFA_min for 10(0*00*0)10001(10*01101100)00*0*11(1)10100...");

$re->set_re("1011|010111|00*0000110110110*0101110");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 1011|010111|00*0000110110110*0101110...");

$re->set_re("0*11*0*000*1*0|10|11*11101010010|11111110*");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 0*11*0*000*1*0|10|11*11101010010|11111110*...");

$re->set_re("1*1010100111110|11111(0*110000110|111)");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 1*1010100111110|11111(0*110000110|111)...");

$re->set_re("0010000000|000110101|00|1|11111|0*0011");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 5, "DFA_min for 0010000000|000110101|00|1|11111|0*0011...");

$re->set_re("10*0010100|10100*010110*01011*0|010011*");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 3, "DFA_min for 10*0010100|10100*010110*01011*0|010011*...");

$re->set_re("01011110*0*101|110100100|1*100010*111*1");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 3, "DFA_min for 01011110*0*101|110100100|1*100010*111*1...");

$re->set_re("1*0100011(111|1|10*0000110*01111101010)");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 2, "DFA_min for 1*0100011(111|1|10*0000110*01111101010)...");

$re->set_re("1|0011*110*11011|00(1(11|00110*110*0*010*0*01*11)001*01101)0100001000*01*1101101|01|0");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 6, "DFA_min for 1|0011*110*11011|00(1(11|00110*110*0*010*0*01*11)001*01101)0100001000*01*1101101|01|0...");

$re->set_re("1|001|1(1)1*0|0(101|01000|01010111|11(0011|0)0011)00|1(0110*0)01|0|0(01101|000011|0|1*000)");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 14, "DFA_min for 1|001|1(1)1*0|0(101|01000|01010111|11(0011|0)0011)00|1(0110*0)01|0|0(01101|000011|0|1*000)...");

$re->set_re("0101000*10101|100(1101|1|0)0|1111101010111*01*1011000011001010*0100010|001|0*");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 9, "DFA_min for 0101000*10101|100(1101|1|0)0|1111101010111*01*1011000011001010*0100010|001|0*...");

$re->set_re("1111*1*10(00|0100*01011011|1|110*010|11*000100010*00(1)1*1(0000(1|0|1010)11101|01(000)))");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 7, "DFA_min for 1111*1*10(00|0100*01011011|1|110*010|11*000100010*00(1)1*1(0000(1|0|1010)11101|01(000)))...");

$re->set_re("1(0(11*1*00|0011)01*1111001*10)01(010111(001101011001|0100110|10)1*01011|001*01(11))");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 10, "DFA_min for 1(0(11*1*00|0011)01*1111001*10)01(010111(001101011001|0100110|10)1*01011|001*01(11))...");

$re->set_re("111|000*010|0(0*00*0|001001111|111111010010)0(1*00)010|011010101001*1111000*011");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 10, "DFA_min for 111|000*010|0(0*00*0|001001111|111111010010)0(1*00)010|011010101001*1111000*011...");

$re->set_re("11|1100011000*10(1110(010111|1001010001*0*110*1|110|01*000110100*0(100*11(010*00))))");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 5, "DFA_min for 11|1100011000*10(1110(010111|1001010001*0*110*1|110|01*000110100*0(100*11(010*00))))...");

$re->set_re("10*00|111110(0*010001001100|1*01111|0|00*0001(101010(000)101)111001|0111001*10*0)");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 10*00|111110(0*010001001100|1*01111|0|00*0001(101010(000)101)111001|0111001*10*0)...");

$re->set_re("11100*00000*1001*0|101|0111(0)000|101110011011101|11|0110010001110|001|1|0|111");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 8, "DFA_min for 11100*00000*1001*0|101|0111(0)000|101110011011101|11|0110010001110|001|1|0|111...");

$re->set_re("1*11000000(01000001000(10)1(01*01(10110*001*0110111001|10010|000010111110*11*)))");
@removed = $re->to_nfa()->to_dfa()->minimize();
ok(($#removed+1) == 4, "DFA_min for 1*11000000(01000001000(10)1(01*01(10110*001*0110111001|10010|000010111110*11*)))...");
