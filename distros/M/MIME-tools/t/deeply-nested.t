use strict;
use warnings;

use Test::More tests => 5;

# Attempt to parse a deeply-nested message

use MIME::Parser;
use MIME::Decoder;
use MIME::Base64 qw(encode_base64);
use IO::File;

my $parser = MIME::Parser->new();
$parser->output_to_core(1);        ### keep the payload out of the filesystem
$parser->max_depth(-1);
$parser->max_parts(-1);
my $entity = $parser->parse_open("testmsgs/deeply-nested.msg");

is(scalar($entity->parts), 1, 'Entity has one part');

my $part = $entity;
for (my $i=0; $i<500; $i++) {
        $part = $part->parts(0);
}

is ($part->mime_type, "text/plain", "Nested part has correct MIME type");
my $body = $part->bodyhandle;
is ($body->as_string, "Here is some text for you\n", "Got expected content");

# Limit parse depth
$parser = MIME::Parser->new();
$parser->output_to_core(1);        ### keep the payload out of the filesystem
$parser->max_depth(500);
$parser->max_parts(-1);
$entity = $parser->parse_open("testmsgs/deeply-nested.msg");
is(scalar($entity->parts), 1, 'Entity has one part');

$parser = MIME::Parser->new();
$parser->output_to_core(1);        ### keep the payload out of the filesystem
$parser->max_depth(499);
$parser->max_parts(-1);
$entity = $parser->parse_open("testmsgs/deeply-nested.msg");
ok(!defined($entity), "Maximum MIME depth was exceeded");

1;
