use strict;
use warnings;

use Test::More;
use Digest::FarmHash qw(
    farmhash32 farmhash64 farmhash128
    farmhash_fingerprint32 farmhash_fingerprint64 farmhash_fingerprint128
);

my $data = 'The quick brown fox jumped over the lazy sleeping dog';
my $seed = 123;

cmp_ok farmhash32($data), '>', 0;
cmp_ok farmhash32($data, $seed), '>', 0;
cmp_ok farmhash64($data), '>', 0;
cmp_ok farmhash64($data, $seed), '>', 0;
cmp_ok farmhash64($data, $seed, $seed), '>', 0;
my ($lo, $hi) = farmhash128($data);
cmp_ok $lo, '>', 0;
cmp_ok $hi, '>', 0;
($lo, $hi) = farmhash128($data, $seed, $seed);
cmp_ok $lo, '>', 0;
cmp_ok $hi, '>', 0;

is farmhash_fingerprint32($data), 2280764877;
is farmhash_fingerprint64($data), 17097846426514660294;
($lo, $hi) = farmhash_fingerprint128($data);
is $lo, 5204402368493418845;
is $hi, 10127018699410655448;

done_testing;
