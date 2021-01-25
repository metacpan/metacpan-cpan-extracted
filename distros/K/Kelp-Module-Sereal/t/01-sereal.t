use strict;
use warnings;

use Test::More;
use Kelp;
use MIME::Base64;

my $app = Kelp->new(mode => 'test');

can_ok $app, 'sereal';

can_ok $app->sereal, qw(encode encoder decode decoder);
isa_ok $app->sereal->encoder, 'Sereal::Encoder';
isa_ok $app->sereal->decoder, 'Sereal::Decoder';

my @documents = (
	{
		key1 => 'val1',
		key2 => 'val2',
	},
	{
		key3 => ['val3', 'val4'],
		key4 => undef,
	},
);

my $res = '';

for my $doc (@documents) {
	$res .= $app->sereal->encode($doc);
}

my $base64_result = <<'BASE64';
PfNybAQAUmRrZXkxZHZhbDFka2V5MmR2YWwyPfNybAQAUmRrZXkzQmR2YWwzZHZhbDRka2V5NCU=
BASE64

is $res, decode_base64($base64_result), 'encode ok';

while (length $res) {
	is_deeply $app->sereal->decode($res), shift @documents, 'decode ok';
}

done_testing;
