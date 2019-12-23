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

# Insert your test code below, the Test::More module is used here so read
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
        "Test of base64 encrypting with $i characters string" )
      or diagErr( $s, $c->decrypt( $c->encrypt($s) ), $c->encrypt($s) );
}

my $data      = md5_hex(rand);
my $secondKey = md5(rand);
ok(
    $c->decryptHex( $c->encryptHex( $data, $secondKey ), $secondKey ) eq $data,
    "Test of hexadecimal encrypting"
  )
  or diagErr(
    $data,
    $c->decryptHex( $c->encryptHex( $data, $secondKey ), $secondKey ),
    $c->encryptHex( $data, $secondKey )
  );

# Test a long value, and replace carriage return by %0A
my $long = Lemonldap::NG::Common::Crypto::srandom()->randpattern( "s" x 1000 );
ok( $c->decrypt( $c->encrypt($long) ) eq $long,
    "Test of long value encrypting" )
  or diagErr(
    $long,
    $c->decryptHex( $c->encryptHex($long) ),
    $c->encryptHex($long)
  );

sub diagErr {
    diag "Expect: $_[0]\nGet   : $_[1]\nCipher: $_[2]";
}
