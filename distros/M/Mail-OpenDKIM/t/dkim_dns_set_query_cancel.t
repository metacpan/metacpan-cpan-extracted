#!/usr/bin/perl -wT

use Test::More tests => 3;
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

sub callback {
	my $closure = shift;

	die("callback called unexpectedly, closure $closure");
}

DNS_SET_QUERY_CANCEL: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	$o->dkim_dns_set_query_cancel({ func => \&callback });

	$o->dkim_close();
}

