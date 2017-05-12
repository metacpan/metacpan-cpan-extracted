#!perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use JSON::XS;

my $data = {
    'three' => [ 1, 2, 3 ],
    'four' => { 'a' => 'b' },
    'five' => [ 'a', 'b', 'c' ],
};
my $json = encode_json($data);

cmpthese(
    -1,
    {   'encode_json' => sub { encode_json($data) },
        'decode_json' => sub { decode_json($json) },
    }
);
