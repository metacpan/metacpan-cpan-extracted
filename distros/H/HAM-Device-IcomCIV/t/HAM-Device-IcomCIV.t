# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HAM-Device-IcomCIV.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 14;
BEGIN { use_ok('HAM::Device::IcomCIV') };

#########################


# Only Class functions are tested! Methods tests would require a working
# Icom radio attached to a serial port.

# Get CI-V Adress

ok ( HAM::Device::IcomCIV::get_civ_adress('IC-R8500') eq 0x4A, 'Get Adress Test 1');
ok ( HAM::Device::IcomCIV::get_civ_adress('IC-756Pro3') eq 0x6e, 'Get Adress Test 2');

# Int to BCD

my $exp = chr(0x90) . chr(0x78) . chr(0x56) . chr(0x34) . chr(0x12);
ok( HAM::Device::IcomCIV::int2bcd( 1234567890, 5 ) eq $exp, 'Int to BCD Test 1');

$exp = chr(0x01) . chr(0x00) . chr(0x00);
ok( HAM::Device::IcomCIV::int2bcd( 1, 3 ) eq $exp, 'Int to BCD Test 2');

$exp = chr(0x90) . chr(0x78) . chr(0x56);
ok( HAM::Device::IcomCIV::int2bcd( 1234567890, 3 ) eq $exp, 'Int to BCD Test 3');

# BCD to Int

my @tst = ( 0x90, 0x78, 0x56, 0x34, 0x12 );
ok( HAM::Device::IcomCIV::bcd2int(  @tst ) eq 1234567890, 'BCD to Int Test 1');

# Icom 2 Mode

ok( HAM::Device::IcomCIV::icom2mode(0x02, 'IC-R8500') eq 'AM', 'Icom to Mode Test 1');
ok( HAM::Device::IcomCIV::icom2mode(0x00, 'IC-706 Mk2') eq 'LSB', 'Icom to Mode Test 2');
ok( HAM::Device::IcomCIV::icom2mode(0x05, 'IC-R7000') eq 'SSB', 'Icom to Mode Test 3');

# Mode 2 Icom

ok( HAM::Device::IcomCIV::mode2icom('AM') eq chr(0x02), 'Mode to Icom Test 1');
ok( HAM::Device::IcomCIV::mode2icom('S-AM') eq chr(0x11), 'Mode to Icom Test 2');

# Icom 2 Filter

ok( HAM::Device::IcomCIV::icom2filter(0x02, 0x02) eq 'NORMAL', 'Icom to Filter Test 1');

# Filter 2 Icom

ok( HAM::Device::IcomCIV::filter2icom('AM', 'NORMAL') eq chr(0x02), 'Filter to Icom Test 2');


