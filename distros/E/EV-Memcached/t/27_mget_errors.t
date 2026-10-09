use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

for my $method (qw(mget mgets)) {
    for my $held (0, 1) {
        my $srv = FakeMemcached->new(script => sub {
            my $c = FakeMemcached->accept(shift);
            if ($held) {
                my $blocker = $c->read_request or exit 0;
                $c->respond(op => $blocker->[0], opaque => $blocker->[1]);
            }
            my $hit = $c->read_request or exit 0;
            my $error = $c->read_request or exit 0;
            $c->respond_hit(op => $hit->[0], opaque => $hit->[1], key => 'a', value => 'v');
            $c->respond(op => $error->[0], opaque => $error->[1],
                status => 0x82, value => 'temporary failure');
            my $fence = $c->read_request or exit 0;
            $c->respond(op => $fence->[0], opaque => $fence->[1]);
            my $next = $c->read_request or exit 0;
            $c->respond(op => $next->[0], opaque => $next->[1]);
            sleep 2;
        });
        my ($result, $error, $probe, @errors);
        my $mc = EV::Memcached->new(path => $srv->path,
            ($held ? (max_pending => 1) : ()),
            on_error => sub { push @errors, $_[0]; EV::break });
        $mc->noop if $held;
        $mc->$method(['a', 'b'], sub {
            ($result, $error) = @_;
            $mc->noop(sub { $probe = $_[0]; EV::break });
        });
        my $t = EV::timer 2, 0, sub { EV::break };
        EV::run;
        is($result, undef, "$method held=$held: partial results are not reported as success");
        like($error // '', qr/^OUT_OF_MEMORY: temporary failure$/,
            "$method held=$held: entry failure reaches the batch callback");
        is($probe, 1, "$method held=$held: connection remains usable");
        is_deeply(\@errors, [], "$method held=$held: no connection error");
        $mc->disconnect;
        $srv->finish;
    }
}

# The first entry error wins; later entry replies are dropped.
{
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        my @r = map { $c->read_request or exit 0 } 1 .. 4;
        $c->respond(op => $r[0][0], opaque => $r[0][1],
            status => 0x82, value => 'first');
        $c->respond(op => $r[1][0], opaque => $r[1][1],
            status => 0x82, value => 'second');
        $c->respond_hit(op => $r[2][0], opaque => $r[2][1], key => 'c', value => 'v');
        $c->respond(op => $r[3][0], opaque => $r[3][1]);
        sleep 2;
    });
    my ($result, $error, @errors);
    my $mc = EV::Memcached->new(path => $srv->path,
        on_error => sub { push @errors, $_[0]; EV::break });
    $mc->mget([qw(a b c)], sub { ($result, $error) = @_; EV::break });
    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;
    is($result, undef, 'several entry errors: no partial results');
    is($error, 'OUT_OF_MEMORY: first', 'several entry errors: first one reported');
    is_deeply(\@errors, [], 'several entry errors: no connection error');
    $mc->disconnect;
    $srv->finish;
}

done_testing;
