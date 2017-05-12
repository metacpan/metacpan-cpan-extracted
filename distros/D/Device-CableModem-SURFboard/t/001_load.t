# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 13;

#1
BEGIN { use_ok( 'Device::CableModem::SURFboard' ); }

my $object = Device::CableModem::SURFboard->new ();
my $errstr = Device::CableModem::SURFboard->errstr();

SKIP: {
	# not much to test if there's no modem to connect to
	skip("Couldn't connect. Is a modem connected?", 12)
		if !$object and $errstr =~ m/^Couldn't connect to/;

	#2
	isa_ok ($object, 'Device::CableModem::SURFboard');

	#3
	like ($object->modelGroup(), qr/^SB5100|SB5101|SBV5120E$/, 'valid modem group');

	#4
	ok ($object->channel(), 'upstream channel');

	#5
	like ($object->dnFreqStr(), qr/^\d+ Hz$/, 'dnstream frequency');

	#6
	ok ($object->dnFreq(), 'dnstream frequency value');

	#7
	like ($object->dnPowerStr(), qr/^[+\d.-]+ dBmV$/, 'dnstream power');

	# dnstream power may be zero

	#8
	like ($object->SNRatioStr(), qr/^[\d.]+ dB$/, 'SNRatio');

	#9
	ok ($object->SNRatio(), 'SNRatio value');

	#10
	like ($object->upFreqStr(), qr/^\d+ Hz$/, 'upstream frequency');

	#11
	ok ($object->upFreq(), 'upstream frequency value');

	#12
	like ($object->upPowerStr(), qr/^[\d.]+ dBmV$/, 'upstream power');

	#13
	ok ($object->upPower(), 'upstream power value');
}

