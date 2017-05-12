# -*- perl -*-

use Test::More;
use File::Temp qw(tempdir);
use Mail::GnuPG;
use MIME::Entity;
use strict;
no warnings 'redefine';         # fix this later

TODO: {
  local $TODO = "agent test unreliable with pre 2.11 gnupg";

my $KEY = "EFEA4EAD"; # 49539D60EFEA4EAD
my $WHO = "Mail::GnuPG Test Key <mail\@gnupg.dom>";

my $GPG;
# if gpg2 exists, use that. Mixing versions causes problems.
if (0 == system ("gpg2 --version  2>&1 >/dev/null")) {
  $GPG="gpg2";
} elsif (0 == system ("gpg --version  2>&1 >/dev/null")) {
  $GPG="gpg";
} else {
  plan skip_all => "gpg2 or gpg in path required for testing agent";
  goto end;
}

unless ( 0 == system("gpg-agent --version 2>&1 >/dev/null")) {
  plan skip_all => "gpg-agent in path required for testing agent";
  goto end;
}

my $tmpdir = tempdir( "/tmp/mgtXXXXX", CLEANUP => 1);

unless (open AGENT, "gpg-agent  --homedir $tmpdir --batch --quiet --disable-scdaemon --allow-preset --daemon|") {
  plan skip_all =>"unable to start gpg-agent";
  goto end;
}

my ($agent_pid,$agent_info);
while (<AGENT>){
  if (m/GPG_AGENT_INFO=([^;]*);/){
    $agent_info=$1;
    $ENV{'GPG_AGENT_INFO'}=$agent_info;
    my @parts=split(':',$agent_info);
    $agent_pid=$parts[1];
  }
}

unless ($agent_info) {
  # is it running on the standard (as of 2.1) socket?
  if (0 == system("gpg-agent --homedir $tmpdir 2>&1 >/dev/null")) {
    $ENV{'GPG_AGENT_INFO'}="$tmpdir/S.gpg-agent:0:1";
  } else {
    plan skip_all => "unable to find gpg agent";
  }
}

my $preset=$ENV{GPG_PRESET_PASSPHRASE} || "/usr/lib/gnupg2/gpg-preset-passphrase";

unless (0 == system("$preset --version 2>&1 >/dev/null")) {
  plan skip_all => "gpg-preset-passphrase not found; set GPG_PRESET_PASSPHRASE in environment to location of binary";
  goto end;
}


unless ( 0 == system("${GPG} --homedir $tmpdir --use-agent --batch --quiet --trusted-key 0x49539D60EFEA4EAD --import t/test-key.pgp 2>&1 >/dev/null")) {
  plan skip_all => "unable to import testing keys";
  goto end;
}

# gpg-preset-passphrase uses the keygrip of the subkey, rather than the id/fingerprint.
unless ( 0 == system ("$preset --homedir $tmpdir --preset -P passphrase " .
		      "AC4FAFD3DC861700DB6109591BAD5F37DB2801A1")
	 && 0 == system ("$preset --homedir $tmpdir --preset -P passphrase " .
		      "1230AEE1345EC41ED8E183011176AC9C74A99513")    ){
  plan skip_all =>"unable to cache passphrase";
  goto end;
}

plan tests => 20;


my $mg = new Mail::GnuPG( key => '49539D60EFEA4EAD',
			  keydir => $tmpdir,
			  use_agent => 1,
			  gpg_path => ${GPG});

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
is( $verify, 0 );
is( $key, $KEY );
is( $who, $WHO );

is( $mg->is_signed($copy), 1 );
is( $mg->is_encrypted($copy), 0 );
}
# Test MIME Encryption Round Trip

$copy = $me->dup;

is( $mg->ascii_encrypt( $copy, $KEY ), 0 );
is( $mg->is_signed($copy), 0);
is( $mg->is_encrypted($copy), 1 );

($verify,$key,$who) = $mg->decrypt($copy);

is( $verify, 0 );
is( $key, undef );
is( $who, undef );

is_deeply($mg->{decrypted}->body,$me->body);

end:
kill 15,$agent_pid if (defined($agent_pid));

}
