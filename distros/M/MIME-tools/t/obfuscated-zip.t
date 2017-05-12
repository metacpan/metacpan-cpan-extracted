use strict;
use warnings;

use Test::More tests => 2;

# Handle a missing type in the Content-Type: header

use MIME::Parser;
my $parser = MIME::Parser->new();
$parser->output_to_core(0);
$parser->output_under("testout");
my $entity = $parser->parse_open("testmsgs/malformed-content-type-zip.msg");

is(scalar($entity->parts), 2, 'Entity has two parts');
is($entity->parts(1)->head->mime_attr('content-type.name'), 'payroll_report_429047_10092013.zip', 'Got expected attachment name');

1;

