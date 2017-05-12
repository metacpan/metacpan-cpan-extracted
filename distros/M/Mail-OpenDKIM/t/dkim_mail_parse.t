#!/usr/bin/perl -wT

use Test::More tests => 4;
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

MAIL_PARSE: {

	my $user_out = 0 x 80;
	my $domain_out = 0 x 80;

	ok(Mail::OpenDKIM::dkim_mail_parse('"Nigel Horne" <njh@example.com>', $user_out, $domain_out) == 0);
	ok($user_out eq 'njh');
	ok($domain_out eq 'example.com');
}
