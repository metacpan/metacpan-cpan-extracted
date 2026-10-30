#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Deep;
use Test::More tests => 63;

use MIME::Entity;
use MIME::Parser;
use lib qw( ./t );

my $parser = MIME::Parser->new();
$parser->output_to_core(1);

my $entity = $parser->parse_open('testmsgs/double-boundary.msg');
my $ans = $entity->head->mime_attr('content-type.@duplicate_parameters');
cmp_deeply($ans, ['boundary'], 'Duplicate "boundary" parameter was detected in bad message');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in bad message');
ok($entity->ambiguous_content(), 'Entity method matches parser method');
$entity = $parser->parse_open('testmsgs/attachment-filename-encoding-UTF8.msg');
$ans  = $entity->head->mime_attr('content-type.@duplicate_parameters');
ok(!defined($ans), 'No duplicate "boundary" parameter was detected in good message');
ok(!$parser->ambiguous_content(), 'Ambiguous content was not detected in good message');
ok(!$entity->ambiguous_content(), 'Entity method matches parser method');

$entity = $parser->parse_open('testmsgs/double-content-type.msg');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with two Content-Type headers');
ok($entity->ambiguous_content(), 'Entity method matches parser method');

$entity = $parser->parse_open('testmsgs/double-content-transfer-encoding.msg');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with two Content-Transfer-Encoding headers');
ok($entity->ambiguous_content(), 'Entity method matches parser method');

$entity = $parser->parse_open('testmsgs/double-content-disposition.msg');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with two Content-Disposition headers');
ok($entity->ambiguous_content(), 'Entity method matches parser method');
ok(!$entity->head->ambiguous_content(), 'Ambiguous content is not in top-level part');
ok(!$entity->parts(0)->head->ambiguous_content(), '... or the first sub-part');
ok($entity->parts(1)->head->ambiguous_content(), '... but it is in the second sub-part');
$entity = $parser->parse_open('testmsgs/double-content-id.msg');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with two Content-Id headers');
ok($entity->ambiguous_content(), 'Entity method matches parser method');

$entity = $parser->parse_open('testmsgs/double-content-disposition-param.msg');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with duplicated Content-Disposition parameters');
ok($entity->ambiguous_content(), 'Entity method matches parser method');

### Now create an entity with ambiguous content
$entity = MIME::Entity->build(From => 'x@example.org',
                              To   => 'y@example.org',
                              'Content-Disposition' => 'attachment; filename="foo"; filename="bar"',
                              Type => 'text/plain',
                              Data => ['Hello, world!']);
ok($entity->ambiguous_content(), 'Newly-built entity correctly detects ambiguous content');

$entity = $parser->parse_open('testmsgs/triple-boundary-one-empty.msg');
$ans = $entity->head->mime_attr('content-type.@duplicate_parameters');
cmp_deeply($ans, ['boundary'], 'Duplicate "boundary" parameter was detected in bad message');
$ans = $entity->head->mime_attr('content-type.@empty_parameters');
cmp_deeply($ans, ['boundary'], 'Empty "boundary" parameter value was detected in bad message');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with 3 boundary parameters, one of them empty');
ok($entity->ambiguous_content(), 'Entity method matches parser method');

$entity = $parser->parse_open('testmsgs/empty-boundary.msg');
$ans = $entity->head->mime_attr('content-type.@duplicate_parameters');
ok(!defined($ans), 'No duplicate parameters');
$ans = $entity->head->mime_attr('content-type.@empty_parameters');
cmp_deeply($ans, ['boundary'], 'Empty "boundary" parameter value was detected in bad message');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with empty boundary parameter');
ok($entity->ambiguous_content(), 'Entity method matches parser method');

$entity = $parser->parse_open('testmsgs/empty-quoted-boundary.msg');
$ans = $entity->head->mime_attr('content-type.@duplicate_parameters');
ok(!defined($ans), 'No duplicate parameters');
$ans = $entity->head->mime_attr('content-type.@empty_parameters');
cmp_deeply($ans, ['boundary'], 'Empty "boundary" parameter value was detected in bad message');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with "" boundary parameter');
ok($entity->ambiguous_content(), 'Entity method matches parser method');

$entity = $parser->parse_open('testmsgs/rfc2231boundary.msg');
$ans = $entity->head->mime_attr('content-type.@boundary_ambiguous');
ok(defined($ans), 'No ambiguous boundary found');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with rfc2231 boundary parameter');
# Ensure that we actually decoded the boundary
is ($entity->head->multipart_boundary, 'X', 'Boundary parameter was decoded');

# And ensure we parsed the message using the decoded boundary
my @parts = $entity->parts;
is (scalar(@parts), 2, 'Got two parts');
is ($parts[0]->head->mime_type, 'text/plain', 'First part is text/plain');
is ($parts[1]->head->mime_type, 'application/octet-stream', 'Second part is application/octet-stream');

$entity = $parser->parse_open('testmsgs/qpboundary.msg');
$ans = $entity->head->mime_attr('content-type.@boundary_ambiguous');
ok(defined($ans), 'No ambiguous boundary found');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with quoted-printable encoded boundary parameter');
# Ensure that we actually decoded the boundary
is ($entity->head->multipart_boundary, 'X', 'Boundary parameter was decoded');

# And ensure we parsed the message using the decoded boundary
@parts = $entity->parts;
is (scalar(@parts), 2, 'Got two parts');
is ($parts[0]->head->mime_type, 'text/plain', 'First part is text/plain');
is ($parts[1]->head->mime_type, 'application/octet-stream', 'Second part is application/octet-stream');

$entity = $parser->parse_open('testmsgs/invalid-boundary.msg');
$ans = $entity->head->mime_attr('content-type.@boundary_ambiguous');
ok(defined($ans), 'No ambiguous boundary found');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with non rfc 2045 conform boundary parameter');

$entity = $parser->parse_open('testmsgs/invalid-quoted-boundary.msg');
$ans = $entity->head->mime_attr('content-type.@boundary_ambiguous');
ok(defined($ans), 'No ambiguous boundary found');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with non rfc 2045 conform boundary parameter');

$entity = $parser->parse_open('testmsgs/unusual-space-in-boundary.msg');
$ans = $entity->head->mime_attr('content-type.@boundary_ambiguous');
ok(defined($ans), 'No ambiguous boundary found');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with unusual white space in boundary parameter');

$entity = $parser->parse_open('testmsgs/double-boundary-with-comment.msg');
$ans = $entity->head->mime_attr('content-type.@duplicate_parameters');
ok(defined($ans), 'No duplicate parameters');
cmp_deeply($ans, ['boundary'], 'Duplicate "boundary" parameter was detected in bad message');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with duplicate boundary parameters, one of them with comment');

# A quoted boundary with trailing whitespace: multipart_boundary() strips it
# (RFC 2046), but parsers keeping the quoted value verbatim see a different
# boundary, so it must be marked ambiguous
$entity = $parser->parse_open('testmsgs/trailing-space-boundary.msg');
$ans = $entity->head->mime_attr('content-type.@boundary_ambiguous');
ok(defined($ans), 'Trailing whitespace in quoted boundary marked ambiguous');
ok($parser->ambiguous_content(), 'Ambiguous content was detected in message with trailing whitespace in boundary parameter');
ok($entity->ambiguous_content(), 'Entity method matches parser method');
is($entity->head->multipart_boundary, 'FOO', 'Boundary parameter was stripped');
@parts = $entity->parts;
is(scalar(@parts), 1, 'Smuggled block is not a MIME part');
like(join('', @{ $entity->epilogue || [] }), qr/evil\.exe/,
     'Smuggled attachment is in epilogue');
# mimic a sanitizer: strip epilogue and write back the stripped boundary
$entity->epilogue([]);
$entity->head->mime_attr('Content-Type.boundary', $entity->head->multipart_boundary);
ok(!$entity->ambiguous_content(), 'Sanitized message is no longer ambiguous');

# Blank filenames should not raise ambiguous content warning
$entity = $parser->parse_open('testmsgs/blank-filename.msg');
ok($entity, 'Got an entity');
ok(!$entity->ambiguous_content(), 'Blank filename parameter not a cause for indicating an ambiguous parse');
is($entity->parts(1)->head->recommended_filename(), undef, 'Got no recommended filename as expected');
