use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok( 'MIME::Base32' ) || BAIL_OUT("Can't use MIME::Base32");
}
can_ok('MIME::Base32', (
	qw(encode_base32hex decode_base32hex),
	qw(encode_09AV decode_09AV),
)) or BAIL_OUT("Something's wrong with the module!");

my $string = 'Hallo world, whats new? 1234567890 abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ .:!%$@#*()[]{}<>"/ ';
my $encoded_hex = '91GMOR3F41RMUSJCCGM20TR8C5Q7683ECLRJU81H68PJ8D9M6SS3IC10C5H66P35CPJMGQBADDM6QRJFE1ON4SRKELR7EU3PF8G42GI38H2KCHQ89554MJ2D9P7L0KAIADA5ALINB1CLK81E78GIA9204CL2GAARBLTNQF1U48NI0';

is(MIME::Base32::encode_base32hex($string),$encoded_hex, 'encode_base32hex: Got the right response');
is(MIME::Base32::decode_base32hex($encoded_hex),$string, 'decode_base32hex: Got the right response');
is(MIME::Base32::encode_09AV($string),$encoded_hex, 'encode_09AV: Got the right response');
is(MIME::Base32::decode_09AV($encoded_hex),$string, 'decode_09AV: Got the right response');

is(MIME::Base32::encode_base32hex(undef), '', 'encode_base32hex: undef passed');
is(MIME::Base32::decode_base32hex(undef), '', 'decode_base32hex: undef passed');

is(MIME::Base32::encode_base32hex(''), '', 'encode_base32hex: empty string passed');
is(MIME::Base32::decode_base32hex(''), '', 'decode_base32hex: empty string passed');

done_testing();
