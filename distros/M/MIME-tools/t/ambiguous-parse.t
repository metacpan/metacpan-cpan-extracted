#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Deep;
use Test::More tests => 20;

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

