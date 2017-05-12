#!/usr/bin/env perl

use strict;
use Test::More tests => 6;

use_ok('HTTP::DAV');
use_ok('HTTP::DAV::Utils');

my $uc_uri = 'http://example.com/escaped_%5B/';
my $lc_uri = 'http://example.com//escaped_%5b/';
my $uri_missing_slash = 'http://example.com/escaped_%5b';
my $different_uri = 'http://example.com/ESCAPED_%5B/';

ok(
	HTTP::DAV::Utils::compare_uris($uc_uri, $lc_uri),
	'Upper and lower case escaping is equivalent'
);
ok(
	HTTP::DAV::Utils::compare_uris($uc_uri, $uri_missing_slash),
	'Upper and lower case escaping is equivalent, even with missing final slash'
);
ok(
	HTTP::DAV::Utils::compare_uris($lc_uri, $uri_missing_slash),
	'Upper and lower case escaping is equivalent, even with missing final slash'
);
ok(
	! HTTP::DAV::Utils::compare_uris($uc_uri, $different_uri),
	'General URI characters are case sensitive'
);

