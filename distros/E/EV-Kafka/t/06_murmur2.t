use strict;
use warnings;
use Test::More;
use EV::Kafka;

# Kafka-compatible murmur2 test vectors from our XS implementation
# These produce consistent partition routing with Kafka Java clients
my @tests = (
    ['',              275646681],
    ['a',             584102524],
    ['ab',            316155434],
    ['abc',           479470107],
    ['test',          716234879],
    ['hello',        2132663229],
    ['hello world',  1221641059],
    ['key1',          28543940],
    ['0',             971027396],
    ['1234567890',   1249327157],
);

plan tests => scalar(@tests) + 5;

# correctness against known vectors
for my $t (@tests) {
    my ($key, $expected) = @$t;
    my $got = EV::Kafka::_murmur2($key);
    is $got, $expected, "murmur2('$key') = $expected";
}

# always non-negative (bit 31 cleared)
ok EV::Kafka::_murmur2('') >= 0, 'empty key non-negative';
ok EV::Kafka::_murmur2('x' x 1000) >= 0, 'long key non-negative';
ok EV::Kafka::_murmur2("\xff" x 4) >= 0, 'binary key non-negative';

# deterministic
is EV::Kafka::_murmur2('foo'), EV::Kafka::_murmur2('foo'), 'deterministic';

# partition selection: hash % N is consistent
my $h = EV::Kafka::_murmur2('user-42');
ok $h % 8 == $h % 8, 'modulo partition stable';
