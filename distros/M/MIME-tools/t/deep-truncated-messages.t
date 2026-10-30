use strict;
use warnings;
use Test::More tests => 2;

use MIME::Parser;

# A message nested 100 deep that ends before any closing boundary
my $msg = '';
$msg .= "Content-Type: multipart/mixed; boundary=b$_\n\n--b$_\n" for 1 .. 100;
$msg .= "Content-Type: text/plain\n\nhello\n";

my $parser = MIME::Parser->new();
$parser->output_to_core(1);
$parser->max_depth(200);
$parser->max_parts(1000);
$parser->parse_data($msg);

my @msgs = $parser->results->msgs;
ok(scalar(@msgs) >= 100, 'One message per level');
is((grep { length($_) > 120 } @msgs), 0, 'Messages do not grow with depth');
