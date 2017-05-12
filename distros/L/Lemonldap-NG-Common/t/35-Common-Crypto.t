# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Common.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 21;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use strict;

BEGIN {
    use_ok('Lemonldap::NG::Common::Crypto');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $c;

ok(
    $c = Lemonldap::NG::Common::Crypto->new(
        'lemonldap-ng-key', Crypt::Rijndael::MODE_CBC()
    ),
    'New object'
);
foreach my $i ( 1 .. 17 ) {
    my $s = '';
    $s = join( '', map { chr( int( rand(94) ) + 33 ) } ( 1 .. $i ) );
    ok( $c->decrypt( $c->encrypt($s) ) eq $s,
        "Test of base64 encrypting with $i characters string" );
}

my $data      = md5_hex(rand);
my $secondKey = md5(rand);
ok(
    $c->decryptHex( $c->encryptHex( $data, $secondKey ), $secondKey ) eq $data,
    "Test of hexadecimal encrypting"
);

# Test a long value, and replace carriage return by %0A
my $long = "f5a1f72e7ab2f7712855a068af0066f36bfcf2c87e6feb9cf4200da1868e1dfe";
my $cryptedlong =
"Da6sYxp9NCXv8+8TirqHmPWwTQHyEGmkCBGCLCX/81dPSMwIQVQNV7X9KG3RrKZfyRmzJR6DZYdU%0Ab75+VH3+CA==";
ok( $c->decrypt($cryptedlong) eq $long, "Test of long value encrypting" );
