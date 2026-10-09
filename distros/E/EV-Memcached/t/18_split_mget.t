use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# Under max_pending an mget waits whole behind the cap: its keys never
# leave without the fence, so dropping the batch strands nothing in
# flight, and skipping the blocker does not lose the batch's hits.

sub run_case {
    my (%arg) = @_;
    my $meth  = $arg{mgets} ? 'mgets' : 'mget';
    my $mode  = $arg{mode};
    my $label = "$meth/$mode";

    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        my $blocker = $c->read_request or exit 0;
        select undef, undef, undef, 0.3;
        $c->respond_hit(op => $blocker->[0], opaque => $blocker->[1], value => 'BVAL');
        while (my $r = $c->read_request) {
            if ($r->[0] == 0x0d && $r->[2] eq 'a') {
                $c->respond_hit(op => $r->[0], opaque => $r->[1],
                    key => 'a', value => 'VA');
            } elsif ($r->[0] == 0x0a) {
                $c->respond(op => $r->[0], opaque => $r->[1]);
            }
        }
    });

    my (@errors, $blocker, $res, $err, $held, $w, $t);
    my $mc = EV::Memcached->new(
        path            => $srv->path,
        max_pending     => 1,
        command_timeout => 500,
        ($mode eq 'expire' ? (waiting_timeout => 200) : ()),
        on_error        => sub { push @errors, $_[0] },
    );
    my $issue = sub {
        $mc->get('blocker', sub { $blocker = $_[0] // "err=$_[1]" });
        $mc->$meth(['a', 'b'], sub { ($res, $err) = @_ });
    };
    # queued while connecting, so the connect-time drain must hold the
    # batch; expiry issues after connect to measure from a known time
    $issue->() unless $mode eq 'expire';
    $mc->on_connect(sub {
        $issue->() if $mode eq 'expire';
        $w = EV::timer 0.1, 0, sub {
            $held = $mc->pending_count == 1 && $mc->waiting_count == 1;
            $mc->skip_waiting if $mode eq 'skip_waiting';
            $mc->skip_pending if $mode eq 'skip_pending';
        };
        $t = EV::timer 1.5, 0, sub { EV::break };
    });
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;

    ok($held, "$label: batch held whole behind the cap");
    if ($mode eq 'skip_pending') {
        is($blocker, 'err=skipped', "$label: blocker skipped");
        is($err, undef, "$label: batch sent after the skip");
        is_deeply([sort keys %{ $res || {} }], ['a'], "$label: hit delivered");
    } else {
        is($blocker, 'BVAL', "$label: in-flight command gets its real response");
        my $want = $mode eq 'expire' ? 'waiting timeout' : 'skipped';
        is($err, $want, "$label: batch failed with '$want'");
    }
    is_deeply(\@errors, [], "$label: no command timeout on an idle connection");
    ok($mc->is_connected, "$label: still connected");
    $mc->disconnect;
    $srv->finish;
}

for my $mgets (0, 1) {
    run_case(mgets => $mgets, mode => $_) for qw(skip_waiting expire skip_pending);
}

done_testing();
