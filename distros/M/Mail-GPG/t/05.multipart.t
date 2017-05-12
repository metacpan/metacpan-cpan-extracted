#!/usr/bin/perl

package Mail::GPG::Test;

use strict;
#no warnings;

use Test::More;
use MIME::Parser;
use MIME::Entity;

SKIP: {
	if ( qx[gpg --version 2>&1 && echo GPGOK] !~ /GPGOK/ ) {
		plan skip_all => "No gpg found in PATH";
	}

	plan tests => 3;

	use_ok ("Mail::GPG::Test");

	my $test = Mail::GPG::Test->new;

        ok($test->init, "Mail::GPG::Test->init");

        my $mg = $test->get_mail_gpg;

        my $entity = MIME::Entity->build(
            From     => $test->get_key_mail,
            Subject  => "Mail::GPG Testmail",
            Data     => "", # a body is *required*, at least an empty one
            Charset  => "iso-8859-1",
            Encoding => "base64",
        );

        $entity->attach(
            Type        => "application/octet-stream",
            Disposition => "inline",
            Data        => [ "A great Ättächment.  \n" x 10 ],
            Encoding    => "base64",
        );

        ok($mg->mime_sign( entity => $entity ), "mime_sign");
}
