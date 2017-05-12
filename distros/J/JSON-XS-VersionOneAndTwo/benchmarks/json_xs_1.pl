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
my $json = to_json($data);

cmpthese(
    -1,
    {   'to_json'   => sub { to_json($data) },
        'from_json' => sub { from_json($json) },
    }
);
