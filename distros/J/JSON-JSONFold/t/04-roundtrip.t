use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use JSON::JSONFold qw(encode_json);

my @cases = (
    [],
    {},
    [1],
    { a => 1 },
    { ids => [1,2,3,4,5,6,7,8] },
    { rows => [[1,20,"Red"], [4000,50,"Yellow"]] },
    { nested => [{ a => [1,2] }, { a => [3,4] }] },
);

for my $i (0 .. $#cases) {
    my $out = encode_json($cases[$i], { compact => 'default' });
    is_deeply(decode_json($out), $cases[$i], "case $i round-trips");
}

done_testing;
