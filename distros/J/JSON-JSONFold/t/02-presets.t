use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use JSON::JSONFold qw(encode_json);

my $data = { ids => [1,2,3,4], meta => { ok => JSON::PP::true } };

for my $compact (qw(off none default low med high max pack fold join)) {
    my $out = encode_json($data, { compact => $compact });
    ok($out, "preset $compact returns output");
    is_deeply(decode_json($out), $data, "preset $compact round-trips");
}

done_testing;
