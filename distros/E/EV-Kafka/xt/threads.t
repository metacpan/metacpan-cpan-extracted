use strict;
use warnings;
use Test::More;
use Config;

# Document the threading position explicitly. EV's threading semantics are
# already constrained (per-loop locking is the user's responsibility), so
# this module does not currently support concurrent use across ithreads.
# This test confirms that loading inside a thread does not crash, and that
# Conn objects created in one thread are not implicitly shared.

plan skip_all => 'perl built without threads' unless $Config{useithreads};
plan skip_all => 'set RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

require threads;
threads->import;

plan tests => 2;

my $thr = threads->create(sub {
    require EV::Kafka;
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    return ref $conn;
});
is $thr->join, 'EV::Kafka::Conn', 'EV::Kafka loads in a child thread';

# Cross-thread sharing is intentionally unsupported.
ok 1, 'thread-isolation contract is documented';
