use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;

# Regression test for the rbuf compaction underflow fixed in batch 3
# (the `if (self->rbuf_len < consumed) return;` guard in
# conn_process_responses).
#
# conn_process_responses dispatches a response BEFORE compacting rbuf,
# then does `rbuf_len -= consumed`. If the dispatched callback tears the
# connection down (user callback -> disconnect() -> conn_handle_disconnect
# -> conn_cleanup), conn_cleanup has already zeroed rbuf_len, and the
# subtraction underflows size_t into a wild memmove (SIGSEGV/SIGBUS).
#
# Trigger: the mock answers TWO queued Metadata requests with a single
# syswrite, so both frames land in the client's rbuf in one read. The
# first response's callback calls disconnect(); with the guard missing,
# the post-dispatch `rbuf_len(0) - consumed` underflows and the process
# dies before any assertion runs (the file exits non-zero / signal).
#
# Verified pre-fix: with the guard reverted this test dies with SIGSEGV.

plan tests => 9;

# Answer ApiVersions; hold each Metadata request until two are queued,
# then write both response frames in ONE syswrite.
my ($conn, $broker) = ready_conn(on_request => sub {
    my ($req, $send, $conn, $ctx) = @_;
    if ($req->{api} == 18) { $send->($req->{corr}, apis_body()); return; }
    if ($req->{api} == 3) {
        push @{ $ctx->{held_meta} }, $req;
        return unless @{ $ctx->{held_meta} } == 2;
        my $body = metadata_v1(topics => { t1 => 1 }, port => $ctx->{port});
        my $out = '';
        for my $r (@{ $ctx->{held_meta} }) {
            my $payload = i32($r->{corr}) . $body;
            $out .= i32(length $payload) . $payload;
        }
        syswrite $conn->{fh}, $out if $conn->{fh};
        return;
    }
});

my (@cb1, @cb2, @errors);
my $disconnects = 0;
# ready_conn installed an on_error that EV::breaks; replace it with a
# recorder. With the rbuf_len guard missing, the underflowed compaction
# leaves the conn processing garbage and a spurious "response too short"
# error fires here — that is the observable pre-fix failure.
$conn->on_error(sub { push @errors, $_[0] });
$conn->on_disconnect(sub { $disconnects++ });

$conn->metadata(undef, sub {
    @cb1 = @_;
    ok !$cb1[1], 'first metadata response dispatched without error';
    ok ref $cb1[0] eq 'HASH' && ref $cb1[0]{topics} eq 'ARRAY',
        'first response parsed (callback runs mid-rbuf)';
    # Tear the connection down while conn_process_responses still holds
    # `consumed` for the frame it just dispatched.
    $conn->disconnect;
    push @cb1, 'disconnect-called';
});
$conn->metadata(undef, sub {
    @cb2 = @_;
    EV::break;
});

my $t = timeout_w();
EV::run;

is $cb1[2], 'disconnect-called',
    'disconnect() ran from inside the response callback';
is $disconnects, 1, 'on_disconnect fired exactly once';
ok !defined($cb2[0]) && defined($cb2[1]) && $cb2[1] eq 'disconnected',
    'still-queued second request failed with "disconnected" by teardown'
    or diag "cb2: result=" . (defined $cb2[0] ? 'set' : 'undef')
          . " err=" . ($cb2[1] // 'undef');
is $conn->pending, 0, 'no callbacks left queued';
ok !$conn->connected, 'conn is disconnected afterwards';
is_deeply \@errors, [],
    'no spurious error from post-teardown rbuf processing';
ok 1, 'survived rbuf compaction after disconnect-from-inside-dispatch';

eval { $conn->disconnect; };
