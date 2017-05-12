# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MIME-Lite-HT-HTML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use File::Basename;
my $dir = dirname __FILE__;

BEGIN { plan tests => 3 };

use MIME::Lite::HT::HTML;
ok(1); # If we made it this far, we're ok.


my $msg = MIME::Lite::HT::HTML->new(
	From        => 'from@example.com',
	To          => 'to@example.com',
	Subject     => 'Subject',
	TimeZone    => 'Europe/Berlin',
	Encoding    => 'quoted-printable',
	Template    => {
		html => './t/data/mail.html',
		text => './t/data/mail.txt',
	},
	Charset     => 'utf8',
);
ok( defined $msg, 1, 'Instantiate MIME::Lite::HT::HTML without any options or params');


my $msg2 = MIME::Lite::HT::HTML->new(
	From        => 'from@example.com',
	To          => 'to@example.com',
	Subject     => 'Subject',
	TimeZone    => 'Europe/Berlin',
	Encoding    => 'quoted-printable',
	Template    => {
		html => $dir . '/data/mail.html',
		text => $dir . '/data/mail.txt',
	},
	TmplOptions => {},
	Charset     => 'utf8',
);
ok( defined $msg2, 1, 'Instantiate MIME::Lite::HT::HTML with empty TmplOptions');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

