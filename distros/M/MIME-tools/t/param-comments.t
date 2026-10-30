use strict;
use warnings;
use Test::More tests => 3;

use MIME::Head;

my $head = MIME::Head->new(["Content-Type: text/plain; (note) charset (x) = us-ascii; format=flowed\n"]);
is($head->mime_attr('content-type.charset'), 'us-ascii', 'Comments around a parameter are skipped');
is($head->mime_attr('content-type.format'), 'flowed', 'Parameter after a comment is parsed');

$head = MIME::Head->new(["Content-Type: text/plain; charset=us-ascii" . ";(a=b" x 50 . "\n"]);
is($head->mime_attr('content-type.charset'), 'us-ascii', 'Unclosed comments do not hide earlier parameters');
