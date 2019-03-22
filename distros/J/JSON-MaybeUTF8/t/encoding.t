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
    (Encode::decode_utf8("\xEF\xBB\xBF") . '{"this has a bom":"Exämple"}') => { "this has a bom" => "Exämple" },
    '{"after bom":"thïs is æxpected to wœrk"}' => { "after bom" => "thïs is æxpected to wœrk" },
);
while(my ($as_json, $as_perl) = splice @cases, 0, 2) {
    subtest $as_json => sub {
        (my $bom_removed = $as_json) =~ s{^\x{feff}}{};
        is(encode_json_text($as_perl), $bom_removed, 'string encoding');
        is(encode_json_utf8($as_perl), Encode::encode_utf8($bom_removed), 'UTF-8 encoding');

        cmp_deeply(decode_json_text($as_json), $as_perl, 'string decoding');
        my $encoded = Encode::encode_utf8($as_json);
        cmp_deeply(decode_json_utf8($encoded), $as_perl, 'UTF-8 decoding');
        done_testing;
    }
}

done_testing;

