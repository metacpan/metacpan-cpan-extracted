use strict;
use warnings;

use Test::More;
use Kelp;
use Sereal qw(encode_sereal decode_sereal);

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

my @res;
my @sereal_res;

for my $doc (@documents) {
	push @res, $app->sereal->encode($doc);
	push @sereal_res, encode_sereal($doc);
}

while (@res) {
	my $doc = shift @documents;

	is_deeply $app->sereal->decode(shift @sereal_res), $doc, 'decode ok';
	is_deeply decode_sereal(shift @res), $doc, 'decode against sereal ok';
}

is scalar @sereal_res, 0, 'fully decoded ok';

done_testing;

