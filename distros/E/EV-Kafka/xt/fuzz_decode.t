use strict;
use warnings;
use Test::More;
use EV::Kafka;

plan skip_all => 'set RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

my $iters = $ENV{FUZZ_ITERS} || 5_000;
plan tests => 4;

# Feed random bytes to each parser and verify nothing crashes. The parser
# should either return a (possibly partial) hashref or undef — never SEGV.
my @apis = qw(metadata produce fetch list_offsets find_coordinator);

srand 42;  # deterministic
my $survived = 0;
for my $i (1..$iters) {
    my $len = int(rand(512));
    my $bytes = join '', map { chr int rand 256 } 1..$len;
    my $api  = $apis[ int rand scalar @apis ];
    my $ver  = int rand 11;
    eval { EV::Kafka::_test_parse_response($api, $ver, $bytes); 1 } or do {
        diag "die on api=$api ver=$ver len=$len: $@";
        next;
    };
    $survived++;
}
ok $survived == $iters, "$iters random parser invocations survived";

# Random bytes through kf_decode_record_batch.
my $batch_survived = 0;
for my $i (1..$iters) {
    my $len = int(rand(2048));
    my $bytes = join '', map { chr int rand 256 } 1..$len;
    eval { EV::Kafka::_test_decode_batch($bytes); 1 } or next;
    $batch_survived++;
}
ok $batch_survived == $iters, "$iters random record-batch decodes survived";

# Random varints.
my $vi_survived = 0;
for my $i (1..$iters) {
    eval { EV::Kafka::_test_varint_roundtrip(int(rand(2 ** 31)) - 2 ** 30); 1 } or next;
    $vi_survived++;
}
ok $vi_survived == $iters, "$iters varint operations survived";

ok 1, 'fuzz harness completed without panic';
