use strict;
use warnings;

use Test::More tests => 2;

# Ticket 52924: Ensure we add < > arround Content-ID header contents.

use MIME::Entity;

my $bare_id = '123456789.09876@host.example.com';

my $e = MIME::Entity->build(
	Path => "./testin/short.txt",
	Id   => $bare_id,
);
is( $e->head->mime_attr('content-id'), "<$bare_id>", '<> added around bare Id value when creating');

undef $e;
$e = MIME::Entity->build(
	Path => "./testin/short.txt",
	Id   => "<$bare_id>",
);
is( $e->head->mime_attr('content-id'), "<$bare_id>", '<> not added around Id value when already present');
