
BEGIN { $| = 1; print "1..45\n"; }
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

use strict;
#use diagnostics;
use Math::Base::Convert qw(:base);

require './recurse2txt';

my @bas4	= @{&DNA};				# w2
my @bas8	= @{&oct};				# w3
my @bas16	= @{&hex};				# w4
my @bas32	= ('a'..'z',3,2,6,4,1,8);		# w5
my @bas64	= @{&m64};				# w6
# use unpopulated b85 for base 128, 256
my @bas128	= (@{&b85},':',' ',('.') x (128 - 87));	# w7
my @bas256	= (@{&b85},':',' ',('.') x (256 - 87));	# w8

# test 2	check for typo's in base statements
print "base wrong length", scalar(@bas256), "nnot "
	unless 256 == scalar(@bas256);
&ok;

my $word	= 'DeadBeef 123456789';
my $exp		= '8849146568042648639992597815658398729';

# test 3	check 128 -> 10 conversion
my $b128to10	= new Math::Base::Convert(\@bas128 =>dec);
my $got		= $b128to10->_cnvtst($word);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 4	check that reverse works
my $b10to128	= new Math::Base::Convert(10,\@bas128);
$got = $b10to128->_cnvtst($got);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $word;
&ok;

# test 5	create 'finish' statement and check that it is OK
my %bas128 = (		# alter 128 base so characters mapped into null upper half
	2,  110,	# are replaced with unused chars in lower half for this test
	3,  121,
	4,   89,
	7,   99,
	8,   98,
	9,  108,
	11,  92,
	14, 100,
	15, 112,
	16, 120
);

# to generate the above array, comment this out, comment out hexDumper test, uncomment foreach (6..6) below,
# uncomment __END__, and uncomment print statements in CalcPP use32wideTObase to get values for substitution
#
while (my($unused,$replace) = each %bas128) {
  my $tmp = $bas128[$replace];
  $bas128[$replace] = $bas128[$unused];
  $bas128[$unused] = $tmp;
}  

my $b256to10 = new Math::Base::Convert(\@bas256 =>dec);
my $f10exp	= '16064749080984572013478665934710512025531948996015099423733838076951077683421663398922255188875825521313661619253019618312613497203478509352';
my $finish	= '  useFROMbaseShortcuts: Math::Base::Convert tests complete';
my $fin10	= $b256to10->_cnvtst($finish);
print "got: $fin10\nexp: $f10exp\nnot "
	unless $fin10 eq $f10exp;
&ok;

# test 7 - 21	check all base's
my @exp = (
  '1010110010101100011100000110110001010000000111100011011000110000001011000100101001001000011011000101000000111000010101100110010001101010011011100100110001110000011011100110110010101010101011000010110001001000011011100101011010101010101010100001011001001000011011000101000010101010101010100001100001100100011000100111001001010000011010100110111010101100011011100101000001101100011011100110110010101100010011000110010001100000011001100101111001010000011011100101000',
  'CCCTCCCTAGTAAGCTATTAAAGGACTGACTAACCTATCCATCAAGCTATTAACGAATTGAGATAGCCAGCGATCTAGTAAGCGAGCTCCCCCCCTACCTATCAAGCGATTGCCCCCCCCAATGATCAAGCTATTACCCCCCCCAAGAAGATAGACAGTCATTAAGCCAGCGCCCTAGCGATTAAGCTAGCGAGCTCCCTATCTAGATAGAAAGAGATGGATTAAGCGATTA',
  '12625434066120074330601304511033050070254621523344616033466252530261103345325252413110330502525241414430471120324672543345015433466254230621403145712033450',
  '56563836280f1b1816252436281c2b3235372638373655561624372b55550b24362855550c32313928353756372836373656263230332f283728',
  'fmvrygyua1gyycyssinridqvtenjxey6donsvkylcinzlkvkqwjbwfbkvkdbsge6sqnjxky2sqnrxgzlcmmrqgmxsqnzi',
  'BWVjg2KA8bGBYlJDYoHCsyNTcmODc2VVYWJDcrVVULJDYoVVUMMjE5KDU3VjcoNjc2ViYyMDMvKDco',
  '1i SD*0G9mMI<68$F oQ@E7%B9:h5)(vjg:5<68&:gCPCdI%~2 R=67v4icPC6o3W2e',
  '  useFROMbaseShortcuts: Math::Base::Convert tests complete'
);

my @base = ( &bin, \@bas4, \@bas8, \@bas16, \@bas32, \@bas64, \@bas128, \@bas256);
$exp = q|0xf	= [0x2f283728,0x26323033,0x36373656,0x37563728,0x31392835,0x55550c32,0xb243628,0x372b5555,0x55561624,0x26383736,0x2b323537,0x2436281c,0x1b181625,0x3836280f,0x5656,];
|;
foreach (0..$#base) {
# comment out above, uncomment below for base128 corrections
#foreach (6..6) {
  my $bc10tobase = new Math::Base::Convert(dec,$base[$_]);
  $got = $bc10tobase->_cnvtst($fin10);
  print "got: $got\nexp: $exp[$_]\nnot "
	unless $got eq $exp[$_];
  &ok;

# comment out these two tests for base128 corrections
  $got = hexDumper($bc10tobase->{b32str});
  print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
  &ok;
}
#__END__
# test 22 - 45	test reversibility
foreach (0..$#base) {
  my $bcbaseto10 = new Math::Base::Convert($base[$_] =>dec);
  $got = $bcbaseto10->_cnvtst($exp[$_]);
  print "got: $got\nexp: $f10exp\nnot "
	unless $got eq $f10exp;
  &ok;

  $got = hexDumper($bcbaseto10->{b32str});
  print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
  &ok;

  delete $bcbaseto10->{b32str};
  my $rv = $bcbaseto10->useFROMbaseShortcuts;
  $got = hexDumper($rv);
  print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
  &ok;
}





