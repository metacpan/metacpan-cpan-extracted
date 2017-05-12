#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use URI::Escape qw/uri_unescape/;

use ok 'Mail::Summary::Tools::ArchiveLink::Gmane';

can_ok( "Mail::Summary::Tools::ArchiveLink::Gmane", "new" );

my $link = Mail::Summary::Tools::ArchiveLink::Gmane->new(
	message_id => '20060712162508.GN19536@woobling.org',
);

isa_ok( $link, "Mail::Summary::Tools::ArchiveLink::Gmane" );

ok( $link->does("Mail::Summary::Tools::ArchiveLink"), "Mail::Summary::Tools::ArchiveLink::Gmane does Mail::Summary::Tools::ArchiveLink" );

can_ok( $link, "message_uri" );

like( $link->message_uri => qr#^http://#, "seems to be a URI" );
like( $link->message_uri => qr#gmane\.org#, "seems to be pointing at gmane" );
like( uri_unescape($link->message_uri), qr/20060712162508\.GN19536\@woobling\.org/, "seems to contain message_id" );

can_ok( $link, "thread_uri" );

like( $link->thread_uri => qr#^http://#, "seems to be a URI" );
like( $link->thread_uri => qr#gmane\.org#, "seems to be pointing at gmane" );
like( uri_unescape($link->thread_uri), qr/20060712162508\.GN19536\@woobling\.org/, "seems to contain message_id" );

