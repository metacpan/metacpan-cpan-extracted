use strict;
use warnings;

use Test::More tests => 4;

use MIME::Parser;
use IO::File;

# Handle a UTF-8 BOM at start of headers

my $parser = MIME::Parser->new();
$parser->output_to_core(1);

my $entity = $parser->parse(IO::File->new('testmsgs/utf8-bom-at-start.msg'));
is ($entity->mime_type, 'multipart/mixed', 'Got expected MIME type');
is ($entity->parts, 2, 'There are two parts');
is ($entity->parts(0)->mime_type, 'text/plain', 'First part is text/plain');
is ($entity->parts(1)->mime_type, 'application/msword', 'Second part is application/msword');
