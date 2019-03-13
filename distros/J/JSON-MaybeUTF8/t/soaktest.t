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

for(1..1000) {
    my $data = {
        "UTF-8-en©ødéd key" => 'a value with 🙆 in it'
    };
    my $encode_text = encode_json_text($data);
    my $encode_utf8 = encode_json_utf8($data);
    my $decode_text = decode_json_text($encode_text);
    my $decode_utf8 = decode_json_utf8($encode_utf8);
    cmp_deeply($decode_text, $decode_utf8, 'UTF-8 and text versions are matching');
    cmp_deeply($decode_text, $data, 'original and text versions are matching');
    cmp_deeply($decode_utf8, $data, 'UTF-8 and original versions are matching');
}

done_testing;

