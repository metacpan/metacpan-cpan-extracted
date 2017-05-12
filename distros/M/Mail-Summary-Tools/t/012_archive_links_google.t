#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use URI::Escape qw/uri_unescape/;

use ok 'Mail::Summary::Tools::ArchiveLink::GoogleGroups';

can_ok( "Mail::Summary::Tools::ArchiveLink::GoogleGroups", "new" );

my $link = Mail::Summary::Tools::ArchiveLink::GoogleGroups->new(
	message_id => '20060712162508.GN19536@woobling.org',
);

isa_ok( $link, "Mail::Summary::Tools::ArchiveLink::GoogleGroups" );

ok( $link->does("Mail::Summary::Tools::ArchiveLink"), "Mail::Summary::Tools::ArchiveLink::GoogleGroups does Mail::Summary::Tools::ArchiveLink" );

can_ok( $link, "message_uri" );

like( $link->message_uri => qr#^http://#, "seems to be a URI" );
like( $link->message_uri => qr#groups.google\.com#, "seems to be pointing at google" );
like( uri_unescape($link->message_uri), qr/20060712162508\.GN19536\@woobling\.org/, "seems to contain message_id" );

can_ok( $link, "thread_uri" );

SKIP: {
	skip "Live google groups tests disabled", 2 unless $ENV{TEST_LIVE_MECH};

	like( $link->thread_uri => qr#^http://#, "seems to be a URI" );
	like( $link->thread_uri => qr#groups.google\.com#, "seems to be pointing at google" );
};

