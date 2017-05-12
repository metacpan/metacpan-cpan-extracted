use strict;
use warnings;

use Test::More tests => 4;

# Handle a double semicolon in the Content-Type: header

use MIME::Head;

my $head = MIME::Head->new->from_file('testmsgs/double-semicolon.msg');

is ($head->mime_type, 'multipart/alternative', 'Got expected MIME type');
is ($head->multipart_boundary, 'foo', 'Got expected boundary');

$head = MIME::Head->new->from_file('testmsgs/double-semicolon2.msg');

is ($head->mime_type, 'multipart/alternative', 'Got expected MIME type');
is ($head->multipart_boundary, 'foo', 'Got expected boundary');
