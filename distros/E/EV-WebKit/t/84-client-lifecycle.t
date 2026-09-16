use v5.10; use strict; use warnings;
use Test::More;
use lib 't/lib';
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use POSIX ();
use Scalar::Util qw(weaken);
use EV;
use EV::WebKit::Client;

# The client's own lifecycle, against a FAKE server in a child process -- no
# browser, no display. Everything here is about the client's bookkeeping: what
# it collects, what it delivers, and when. A real browser would only make these
# slower and flakier, and a same-process server cannot serve a BLOCKING client
# at all (it needs this process's loop, which the client is busy blocking).

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/fake.sock";

my $srv = IO::Socket::UNIX->new(Local => $path, Listen => 5)
    or plan skip_all => "cannot bind a unix socket here: $!";

my $parent_pid = $$;
my $server_pid = fork;
defined $server_pid or plan skip_all => "cannot fork: $!";
unless ($server_pid) {
    # greet every client, then read and discard until it goes away
    my @keep;
    while (my $c = $srv->accept) {
        syswrite $c, EV::WebKit::Protocol::encode({ ev => 'hello', proto => 1 });
        push @keep, $c;              # hold it open; the client decides when to leave
        # non-blocking drain so one stalled client cannot wedge the others
        $_->blocking(0) for @keep;
        for my $k (@keep) { sysread $k, my $junk, 65536 }
    }
    POSIX::_exit(0);
}
close $srv;
# Only the parent reaps, and only with a real pid: in the child $server_pid is
# 0, and `kill TERM, 0` signals the whole PROCESS GROUP -- which killed the
# harness itself, reported as "exited 15".
END {
    return unless $$ == $parent_pid && $server_pid;
    # local $?: waitpid leaves the reaped child's status there, and perl uses $?
    # as the script's own exit code -- so reaping a TERMed helper made a file
    # whose every test passed exit 15.
    local $?;
    kill 'TERM', $server_pid;
    waitpid $server_pid, 0;
}

sub spin { my $t = EV::timer($_[0] // 0.1, 0, sub { EV::break }); EV::run; undef $t }

# This file drives a BLOCKING client in this process, and a blocking client has
# no timeout of its own: a client regression -- the callback croak removed, the
# event/predicate order swapped -- turns `connect` or a call into an unbounded
# wait, which under `make test` (and CI, which sets no job timeout) would hang
# forever. The alarm does not turn that into a per-file failure: `Bail out!`
# aborts the harness, so the rest of the run is skipped. What it buys is a
# BOUNDED abort with a diagnosis attached instead of an unbounded hang with
# none. Every sibling that risks this runs its client in a child under
# `timeout`; here an alarm is enough, since there is no child to reap.
#
# Baseline is 3.0s wall / 0.09s CPU, of which ~2.5s is fixed spin() sleeps that
# do not stretch under load, so the margin is ~20x.
my $DEADLINE = 60;
$SIG{ALRM} = sub {
    print "Bail out!  t/84: a client call blocked for ${DEADLINE}s -- aborting rather than hanging the run\n";
    kill 'TERM', $server_pid if $$ == $parent_pid && $server_pid;
    POSIX::_exit(1);
};
alarm $DEADLINE;

# --- an ev client the caller merely drops must be collected -----------------
# The read watcher lives ON the client and captured it strongly, so DESTROY
# never ran: the fd stayed open and anything in flight was never resolved.
{
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    weaken(my $w = $c);
    undef $c;
    ok(!defined $w, 'an ev client with no other reference is collected when dropped');
}

# ...including one with a request in flight, which must also be told
{
    my ($got, $err);
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    $c->title(sub { ($got, $err) = @_ });
    weaken(my $w = $c);
    undef $c;
    spin(0.2);
    ok(!defined $w, 'and one with a request in flight is collected too');
    is($err, 'disconnected', '...with the pending callback resolved, not dropped')
        or diag('err=' . ($err // 'undef'));
}

# The element-returning methods carry a $post closure, and THAT captured the
# client strongly after the watchers had been fixed -- so it needs its own case.
{
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    $c->find('#never-answered', sub { });
    is(scalar keys %{ $c->{pending} }, 1, 'precondition: the element request is pending')
        or diag('nothing was in flight, so the $post closure this block is about never existed');
    weaken(my $w = $c);
    undef $c;
    spin(0.2);
    ok(!defined $w, 'an element-returning request in flight does not pin the client either');
}

# --- a failure is DELIVERED, never thrown, and never on the caller's stack --
{
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    my ($fired, $err, $returned);
    my $ok = eval {
        # a scalar ref cannot be JSON: the encode fails on a healthy connection
        $c->go(\'not encodable', sub { $fired = 1; $err = $_[1] });
        $returned = 1;
        1;
    };
    ok($ok, 'an unencodable argument does not croak out of the call') or diag $@;
    ok($returned && !$fired, '...and the callback has not fired yet when it returns');
    spin(0.2);
    ok($fired, '...it arrives on a later tick');
    like($err // '', qr/encode/i, '...carrying the reason');
    is(scalar keys %{ $c->{pending} }, 0, '...and nothing is left pending');
    $c->disconnect;
}

# --- events are buffered when nothing is handling them, and bounded ---------
{
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    $c->events;   # drain the greeting, which ev mode buffers like any other event
    $c->_event({ ev => 'console', n => $_ }) for 1 .. 5;
    my @e = $c->events;
    is(scalar @e, 5, 'an ev client with no on_event buffers events like a blocking one');
    is(scalar($c->events), 0, '...and events() drains them');

    my $cap = EV::WebKit::Client::MAX_EVENT_BACKLOG();
    $c->_event({ ev => 'console', n => $_ }) for 1 .. $cap + 5;
    my @kept = $c->events;
    is(scalar @kept, $cap, 'the backlog is capped');
    is($kept[0]{n}, 6, '...discarding the OLDEST, so the most recent are the ones kept');
    $c->disconnect;
}

# screenshot carries its own $post closure, on a different code path from
# _call_el's -- weakening one did not weaken the other.
{
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    $c->screenshot({ bytes => 1 }, sub { });
    weaken(my $w = $c);
    undef $c;
    spin(0.2);
    ok(!defined $w, 'a screenshot in flight does not pin the client either');
}

# the write half of the deferred-failure path (the encode half is above): a
# call on a connection already known to be gone must still be ANSWERED, and on
# a later tick like every other failure here
{
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    $c->disconnect;
    my ($fired, $err);
    $c->title(sub { $fired = 1; $err = $_[1] });
    ok(!$fired, 'a call on a closed connection has not answered by the time it returns');
    spin(0.2);
    ok($fired, '...but it does answer');
    like($err // '', qr/closed|connection/i, '...with the reason');
    is(scalar keys %{ $c->{pending} }, 0, '...and leaves nothing pending');
}

# release forwards its arguments; passing [] discarded the caller's callback
# before _cb could find it, which in ev mode -- where one is required -- made
# every spelling of release croak.
{
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    my $el = EV::WebKit::Client::Element->_new($c, 1);
    ok(eval { $el->release(sub { }); 1 }, 'release accepts a callback in ev mode')
        or diag $@;
    $c->disconnect;
}

# an ev client really does receive events off the wire, not just ones pushed
# into it by hand
{
    my @seen;
    my $c = EV::WebKit::Client->connect($path, ev => 1, on_event => sub { push @seen, $_[0] });
    spin(0.3);
    ok(scalar(grep { $_ eq 'hello' } @seen), 'an ev client dispatches an event that arrived over the socket')
        or diag('saw: ' . (join(',', @seen) || '(none)'));
    $c->disconnect;
}

# --- a dead socket resolves its owed callbacks on a TICK, not inline ---------
# _ev_gone is reached from inside _write, i.e. from the middle of the very
# method the caller just invoked. Delivering there ran that request's callback
# -- and every earlier one still in flight -- BEFORE the method returned, so a
# caller doing `$c->go($u, $cb); $state = 'navigating';` had $cb observe the
# state it was about to set.
{
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    my ($fired, $err) = (0, undef);
    $c->title(sub { $fired++; $err = $_[1] });
    is(scalar keys %{ $c->{pending} }, 1, 'premise: the request is in flight');
    $c->_ev_gone('socket went away');
    is($fired, 0, 'a socket discovered dead does not run owed callbacks on the caller stack');
    spin(0.1);
    is($fired, 1, '...it runs them on the next tick');
    like($err // '', qr/socket went away/, '...with the reason it died of');
}

# --- a callback in blocking mode is a mistake, and says so ------------------
{
    my $c = EV::WebKit::Client->connect($path);
    ok(!eval { $c->title(sub { }); 1 }, 'a callback in blocking mode croaks');
    like($@, qr/ev => 1/, '...naming what the caller meant');
    $c->disconnect;
}

# --- connect validates its one callback option ------------------------------
ok(!eval { EV::WebKit::Client->connect($path, on_event => 'not a code ref'); 1 },
   'connect croaks on a non-coderef on_event');

# --- a dying callback in _defer_err is caught by _deliver --------------------
{
    my $c = EV::WebKit::Client->connect($path, ev => 1);
    spin(0.2);
    my $warned;
    local $SIG{__WARN__} = sub { $warned = $_[0] if $_[0] =~ /callback died/ };
    $c->go(*STDIN, sub { die "boom\n" });
    spin(0.1);
    ok($warned, '_defer_err caught the dying callback safely via _deliver');
    like($warned, qr/boom/, '...with the expected error message');
    $c->disconnect;
}

done_testing;
