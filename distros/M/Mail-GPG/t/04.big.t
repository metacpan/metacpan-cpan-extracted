#!/usr/bin/perl

package Mail::GPG::Test;

use strict;
#no warnings;

use Test::More;
use MIME::Parser;

SKIP: {
	if ( qx[gpg --version 2>&1 && echo GPGOK] !~ /GPGOK/ ) {
		plan skip_all => "No gpg found in PATH";
	}

	plan tests => 5;

	use_ok ("Mail::GPG::Test");

	my $test = Mail::GPG::Test->new;

	ok($test->init, "Mail::GPG::Test->init");

	my $mg = $test->get_mail_gpg;

	ok($mg, "Mail::GPG->new");

	my $key_id = $mg->query_keyring (
		search => $test->get_key_mail,
	);

	ok ($key_id eq $test->get_key_id, "Key ID retrieved");

	$test->big_test ( mg => $mg );
}
