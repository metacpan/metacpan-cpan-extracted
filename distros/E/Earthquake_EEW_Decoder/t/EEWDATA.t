# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl EEWDATA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Earthquake::EEW::Decoder') };

use Earthquake::EEW::Decoder;
my $eew;
ok $eew= Earthquake::EEW::Decoder->new();
$data = <<EoF;
47 03 00 061004150000 C11
061004145930
ND20061004145955 NCPN01
9762 N336 E1362 040
PRC0000/
CAI 0000
CPI 0000
CBI 000
PAI 9936 9941 9934 9943 9942
PPI 9240 9300 9180 9210 9220 9230 9250 9260 9270 9280 9290
9360 9370 9390 9330
PBI 462 551 550 461 400 401 432 442 443 450 451 460
500 501 510 511 520 521 531 532 535 540 600 601
610 630 631 581 611
NCP
  ND20061004145955 NCN001 JD////////////// JN///
  469 N336 E1362 040 69 6- RK33333 RT1//// RC0////
EBI 462 S6-5+ 150030 00 551 S6-5+ 150030 00
    550 S5+5- 150035 00 461 S5-5- 150035 00
9999=
EoF
my $d;
ok $d = $eew->read_data($data);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

