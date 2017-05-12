# -*- perl -*-

use Test::More;
use File::Temp qw(tempdir);
use Mail::GnuPG;
use MIME::Entity;
use strict;

my $FULL_KEY = "49539D60EFEA4EAD";
my $KEY = substr($FULL_KEY,-8,8);

my $WHO = "Mail::GnuPG Test Key <mail\@gnupg.dom>";

require('t/import_keys.pl');
my $gpghome=import_keys('t/test-key.pgp',$FULL_KEY);
unless (defined($gpghome)){
  plan skip_all => "failed to import GPG keys for testing";
  goto end;
}

plan tests => 20;


my $mg = new Mail::GnuPG( key => '49539D60EFEA4EAD',
			  keydir => $gpghome,
			  passphrase => 'passphrase');

isa_ok($mg,"Mail::GnuPG");

my $line = "x\n";
my $string = $line x 100000;

my $copy;
my $me =  MIME::Entity->build(From    => 'me@myhost.com',
			      To      => 'you@yourhost.com',
			      Subject => "Hello, nurse!",
			      Data    => [$string]);
# Test MIME Signing Round Trip

$copy = $me->dup;

is( $mg->mime_sign( $copy ), 0 );

my ($verify,$key,$who) = $mg->verify($copy);
is( $verify, 0 );
is( $key, $KEY );
is( $who, $WHO );

is( $mg->is_signed($copy), 1 );
is( $mg->is_encrypted($copy), 0 );

# Test Clear Signing Round Trip

$copy = $me->dup;

is( $mg->clear_sign( $copy ), 0 );

{ my ($verify,$key,$who) = $mg->verify($copy);
is( 0, $verify );
is( $KEY, $key );
is( $WHO, $who );

is( 1, $mg->is_signed($copy) );
is( 0, $mg->is_encrypted($copy) );
}
# Test MIME Encryption Round Trip

$copy = $me->dup;

is( $mg->ascii_encrypt( $copy, $KEY ), 0 );
is( $mg->is_signed($copy), 0  );
is( $mg->is_encrypted($copy), 1 );

($verify,$key,$who) = $mg->decrypt($copy);

is( $verify, 0 );
is( $key, undef );
is( $who, undef);

is_deeply($mg->{decrypted}->body,$me->body);

end:
