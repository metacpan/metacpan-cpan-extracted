# -*- perl -*-

use Test::More;
use Mail::GnuPG;
use MIME::Entity;
use File::Temp qw(tempdir);

use strict;

plan tests => 5;

# Main program
my $parser = new MIME::Parser;
$parser->output_to_core(1);

my $entity= $parser->parse_open("t/msg/inline-encrypted-qp.eml") ;
isa_ok($entity,"MIME::Entity");

my $KEY = "EFEA4EAD"; # 49539D60EFEA4EAD
my $WHO = "Mail::GnuPG Test Key <mail\@gnupg.dom>";

unless ( 0 == system("gpg --version 2>&1 >/dev/null") ) {
  plan skip_all => "gpg in path required for testing round-trip";
  goto end;
}

my $tmpdir = tempdir( "mgtXXXXX", CLEANUP => 1);

unless ( 0 == system("gpg --homedir $tmpdir --trusted-key 0x49539D60EFEA4EAD --import t/test-key.pgp 2>&1 >/dev/null")) {
  plan skip_all => "unable to import testing keys";
  goto end;
}


my $mg = new Mail::GnuPG( key => '49539D60EFEA4EAD',
			  keydir => $tmpdir,
			  passphrase => 'passphrase');

isa_ok($mg,"Mail::GnuPG");

my ($return,$keyid,$uid) = $mg->decrypt($entity);
is($return,0,"decrypt success");
ok(!defined($keyid) && !defined($uid), "message unsigned");

is($mg->{decrypted}->as_string,
"
this is some 8-bit text:
בכלףü


","plaintext");

end:
