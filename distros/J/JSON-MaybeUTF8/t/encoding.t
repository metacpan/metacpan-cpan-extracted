use strict;
use warnings;

use utf8;

BEGIN {
    # this is so wrong. note how it doesn't even work if you
    # move this after the Test2 load.
    binmode STDOUT, ':encoding(UTF-8)';
    binmode STDERR, ':encoding(UTF-8)';
}

use Test::More;
use Test::Deep;

use JSON::MaybeUTF8 qw(:v1);
use Encode;

my @cases = (
    '{"x":123}' => { x => 123 },
    '{"x":"Exämple"}' => { x => "Exämple" },
);
while(my ($as_json, $as_perl) = splice @cases, 0, 2) {
    subtest $as_json => sub {
        is(encode_json_text($as_perl), $as_json, 'string encoding');
        is(encode_json_utf8($as_perl), Encode::encode_utf8($as_json), 'UTF-8 encoding');

        cmp_deeply(decode_json_text($as_json), $as_perl, 'string decoding');
        cmp_deeply(decode_json_utf8(Encode::encode_utf8($as_json)), $as_perl, 'UTF-8 decoding');
        done_testing;
    }
}

done_testing;

