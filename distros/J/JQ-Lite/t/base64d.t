use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my @decoded = $jq->run_query('"aGVsbG8h"', '@base64d');
is_deeply(\@decoded, ['hello!'], '@base64d decodes base64 text');

my @roundtrip = $jq->run_query('{"foo":"bar"}', '@base64 | @base64d');
is_deeply(\@roundtrip, ['{"foo":"bar"}'], '@base64d reverses @base64 output');

my $ok = eval { $jq->run_query('"not-base64"', '@base64d'); 1 };
my $error = $@;

ok(!$ok, '@base64d throws on invalid input');
like($error, qr/\@base64d\(\): input must be base64 text/, 'invalid base64 input reports descriptive error');

done_testing();
