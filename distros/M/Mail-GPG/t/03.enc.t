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

	plan tests => 31;

	use_ok ("Mail::GPG::Test");

        foreach my $use_long_key_ids ( 0, 1 ) {
	    my $test = Mail::GPG::Test->new(
                use_long_key_ids => $use_long_key_ids
            );

	    ok($test->init, "Mail::GPG::Test->init");

	    my $mg = $test->get_mail_gpg;

	    ok($mg, "Mail::GPG->new");

	    my $key_id = $mg->query_keyring (
		    search => $test->get_key_mail,
	    );

	    ok ($key_id eq $test->get_key_id, "Key ID retrieved");

	    foreach my $encoding ( qw( base64 quoted-printable ) ) {
		    foreach my $method ( qw( armor_encrypt armor_sign_encrypt
					     mime_encrypt  mime_sign_encrypt ) ) {
		        $test->enc_test (
			    mg       => $mg,
			    method   => $method,
			    encoding => $encoding,
		        );
		        $test->enc_test (
			    mg       => $mg,
			    method   => $method,
			    encoding => $encoding,
			    attach   => 1,
		        ) if $method =~ /mime/;
		    }
	    }
        }
}
