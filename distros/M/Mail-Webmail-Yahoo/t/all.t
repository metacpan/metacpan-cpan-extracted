use Test;

BEGIN { plan tests => 4; }; 


## Did the package load ok?
use Mail::Webmail::Yahoo;

ok(1);


## The tests that follow require a username/ password, and an optional email
## address.

print STDERR qq{
In order to test more complete functionality, I will require valid yahoo.com
account details. You may skip this step by simply hitting enter for the
username.

Note that you will need to be connected to the internet for the remaining
tests to work.
};


my $y_username = '';
my $y_password = '';
my $email      = '';

print STDERR "Yahoo username: ";
my $temp_u = <STDIN>;
chomp $temp_u;

if ($temp_u eq '') {
	print STDERR "Skipping all remaining tests.\n";
} else {
	$y_username = $temp_u;
	print STDERR "Yahoo password: ";
# Cheap method of hiding password as input - may not work on all systems, but
# this _is_ a test..
	eval { system("/bin/stty -echo") };
	if ($@) { warn "Password will be visible when entered.\n" }
	my $temp_p = <STDIN>;
	eval { system("/bin/stty echo") };
	chomp $temp_p;
	$y_password = $temp_p;
	print STDERR qq{
If you like, I can email a short message to an account you provide, for your
own verification of a successful install. If you do not provide an email
address, I will still perform the 'send' test but the results will be sent
to the package author at sdrabble\@cpan.org. Otherwise the message will be
sent to this address plus the one you enter.
The subject of this message will be 

  Mail::Webmail::Yahoo Installation Results

If you do not wish to send a test message at all, enter 'none' for the email
address.	
};

	print STDERR "Send results to: ";
	my $temp_e = <STDIN>;
	chomp $temp_e;
	$email = $temp_e || 'sdrabble@cpan.org';

}
	

## Attempt to create an object..
my $yahoo;

if ($y_username) {
	$yahoo = new Mail::Webmail::Yahoo(
		username => $y_username,
		password => $y_password,
		cookie_file => './cookies',
	);
}

skip(!$y_username, defined $yahoo, 1, $@);

## Make sure we can login..

my $l_ok = 0;
if ($y_username) {
	$l_ok = $yahoo->login;
}

skip(!$y_username, $l_ok, 1, $@);


## Impossible to test if the user has any messages (and if so, did we download
## one correctly) without knowing in advance what those messages are.
## Therefore, no tests for message retrieval.
# TODO: ask the user for a message subject known to them, and download it.


## Attempt to send a message..

my $sr = 0;
if ($y_username && $email ne 'none') {
	$sr = $yahoo->send(
		$email,
		'Mail::Webmail::Yahoo Installation Results',
		"Installation successful (v$Mail::Webmail::Yahoo::VERSION).",
		);
}

skip(!$y_username || $email eq 'none', $sr, 1, $@);

# vim:ft=perl
