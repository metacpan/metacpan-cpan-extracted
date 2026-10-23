use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_or_skip js_or_skip);
use EV;
use EV::Nats;
use EV::Nats::JetStream;

my ($host, $port) = nats_or_skip();
my $nats   = EV::Nats->new(host => $host, port => $port);
my $js     = EV::Nats::JetStream->new(nats => $nats, timeout => 2000);
my $stream = "EV_NATS_TEST_JS_$$";

js_or_skip($nats, sub {
    my ($done) = @_;
    $js->stream_create({ name => $stream, subjects => ["evnats.test.$$.>"] },
                       sub { $done->($_[1]) });
});

plan tests => 17;
my $guard;  # kept: an unkept EV::timer never fires
pass 'stream_create';

# Publish three messages with ack
my @ack_seqs;
my $publish_one;
$publish_one = sub {
    my $i = shift;
    $js->js_publish("evnats.test.$$.msg", "payload-$i", sub {
        my ($ack, $err) = @_;
        diag "publish err: $err" if $err;
        push @ack_seqs, $ack->{seq} if $ack;
        if ($i < 3) { $publish_one->($i + 1) }
        else        { EV::break }
    });
};
$publish_one->(1);
$guard = EV::timer(5, 0, sub { EV::break });
EV::run;
is scalar @ack_seqs, 3, 'js_publish acked 3 messages';

# Pull-fetch via durable consumer
$js->consumer_create($stream, {
    durable_name => 'puller',
    ack_policy   => 'explicit',
}, sub {
    my (undef, $err) = @_;
    diag "consumer_create err: $err" if $err;
    EV::break;
});
$guard = EV::timer(3, 0, sub { EV::break });
EV::run;

my $fetched;
$js->fetch($stream, 'puller', { batch => 3, expires => 1_000_000_000 }, sub {
    my ($msgs, $err) = @_;
    $fetched = $err ? "ERR $err" : $msgs;
    EV::break;
});
$guard = EV::timer(5, 0, sub { EV::break });
EV::run;
ok ref($fetched) eq 'ARRAY', 'fetch returned an array';
is scalar @$fetched, 3, 'fetch got 3 messages' if ref $fetched eq 'ARRAY';

# fetch on an exhausted consumer: empty batch, no error
my ($empty_nw, $empty_nw_err, $empty_ex, $empty_ex_err, $nw_elapsed);
my $nw_t0 = EV::now;
$js->fetch($stream, 'puller', { batch => 3, no_wait => 1 }, sub {
    ($empty_nw, $empty_nw_err) = @_;
    $nw_elapsed = EV::now - $nw_t0;
    $js->fetch($stream, 'puller', { batch => 3, expires => 200_000_000 }, sub {
        ($empty_ex, $empty_ex_err) = @_;
        EV::break;
    });
});
$guard = EV::timer(5, 0, sub { EV::break });
EV::run;
ok ref($empty_nw) eq 'ARRAY' && @$empty_nw == 0 && !$empty_nw_err,
    'no_wait fetch on empty consumer returns an empty batch';
ok defined($nw_elapsed) && $nw_elapsed < 2, 'no_wait answers at once'
    or diag "took: " . ($nw_elapsed // '(never)') . "s";
ok ref($empty_ex) eq 'ARRAY' && @$empty_ex == 0 && !$empty_ex_err,
    'expiring fetch on empty consumer returns an empty batch';

# publish with no matching stream times out instead of hanging
my $js_fast = EV::Nats::JetStream->new(nats => $nats, timeout => 300);
my $nostream_err = '';
$js_fast->js_publish("definitely.nostream.$$.x", 'p', sub {
    $nostream_err = $_[1] // '';
    EV::break;
});
$guard = EV::timer(5, 0, sub { EV::break });
EV::run;
ok $nostream_err ne '', 'publish with no stream reports an error'
    or diag 'got no error';

# message get, consumer info/delete, purge, list
my ($mg_subj, $ci_name, $cd_err, $purge_ok, $listed);
$js->stream_msg_get($stream, { seq => 1 }, sub {
    $mg_subj = $_[0] ? $_[0]->{message}{subject} : undef;
    $js->consumer_info($stream, 'puller', sub {
        $ci_name = $_[0] ? $_[0]->{name} : undef;
        $js->consumer_delete($stream, 'puller', sub {
            $cd_err = $_[1];
            $js->stream_purge($stream, sub {
                $purge_ok = $_[0] ? 1 : 0;
                $js->stream_list(sub {
                    my ($l) = @_;
                    $listed = $l && $l->{streams}
                        && grep { $_->{config}{name} eq $stream } @{$l->{streams}};
                    EV::break;
                });
            });
        });
    });
});
$guard = EV::timer(8, 0, sub { EV::break });
EV::run;
is $mg_subj, "evnats.test.$$.msg", 'stream_msg_get returns the message';
is $ci_name, 'puller', 'consumer_info round-trip';
ok !$cd_err, 'consumer_delete succeeds' or diag "err: $cd_err";
ok $purge_ok, 'stream_purge succeeds';
ok $listed, 'stream_list includes the stream';

# stream_update + consumer_list
my ($upd_mm, $cl_n);
$js->stream_update({ name => $stream, subjects => ["evnats.test.$$.>"], max_msgs => 10 }, sub {
    $js->stream_info($stream, sub {
        $upd_mm = $_[0] ? $_[0]->{config}{max_msgs} : undef;
        $js->consumer_list($stream, sub {
            my ($l) = @_;
            $cl_n = ($l && $l->{consumers}) ? scalar(@{$l->{consumers}}) : -1;
            EV::break;
        });
    });
});
$guard = EV::timer(8, 0, sub { EV::break });
EV::run;
is $upd_mm, 10, 'stream_update applies';
is $cl_n, 0, 'consumer_list empty after delete';

# stream_info round-trip
$js->stream_info($stream, sub {
    my ($info, $err) = @_;
    ok !$err && $info->{config}{name} eq $stream, 'stream_info round-trip'
        or diag "err: $err";
    EV::break;
});
$guard = EV::timer(3, 0, sub { EV::break });
EV::run;

# fetch reports a consumer deleted mid-pull as an error, not an empty batch
my $derr409;
$js->consumer_create($stream, { durable_name => 'doomed', ack_policy => 'none' }, sub {
    $js->fetch($stream, 'doomed', { batch => 5, expires => 10_000_000_000 }, sub {
        $derr409 = $_[1];
        EV::break;
    });
    my $dt; $dt = EV::timer(0.5, 0, sub {
        undef $dt;
        $js->consumer_delete($stream, 'doomed', sub {});
    });
});
$guard = EV::timer(12, 0, sub { EV::break });
EV::run;
like $derr409, qr/409/, 'deleted-mid-fetch consumer errors'
    or diag 'err was: ' . ($derr409 // '(undef)');

# Cleanup
$js->stream_delete($stream, sub { EV::break });
$guard = EV::timer(3, 0, sub { EV::break });
EV::run;
$nats->disconnect;
