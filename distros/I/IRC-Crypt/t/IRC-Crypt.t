# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IRC-Crypt.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 6 };
use IRC::Crypt;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $plaintext = 'Hello, World!';
my $chan = '#test';
my $key = 'test';
my $nick = 'Fook';

IRC::Crypt::add_default_key($chan, $key) && ok(2);
my $c = IRC::Crypt::encrypt_message_to_address($chan, $nick, $plaintext);
defined($c) && ok(3);
my ($p,$n,$t) = IRC::Crypt::decrypt_message( $c );
if(defined($n))
{
	ok(4);
}
else
{
	fail('decrypt');
	diag($p);
}
SKIP: {
	skip "Decrypt failed.", 2 unless defined($n);
	$n eq $nick && ok(5);
	$p eq $plaintext && ok(6);
}

