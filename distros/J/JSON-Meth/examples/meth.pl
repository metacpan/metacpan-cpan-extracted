#!perl

use strict;
use warnings;
use 5.010;
use lib qw{lib ../lib};

use JSON::Meth;

my $data = {
    foo => 'bar',
    baz => 'ber',
    cow => 'moo',
    mer => [
        meer => 1,
        moor => {
            meh => 'hah',
            hih => [
                'hoh',
                undef,
                0,
            ]
        },
    ],
};

my $json_str = $data->$j;

say "Our encoded JSON is $json_str"; # print JSON-encoded string

say $json_str->$j->{cow}; # says "moo"


__END__