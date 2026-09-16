use v5.10; use strict; use warnings;
use Test::More;
use lib 't/lib'; use TWK; TWK::skip_unless_available(); use TCTL;
use File::Temp qw(tempdir);
use EV; use EV::WebKit; use EV::WebKit::Control;

# A client driving a window a HUMAN is also using must hear about what it did not
# ask for -- above all, the human navigating. That is the whole reason
# on_navigate exists, and the reason a visible browser is worth controlling at
# all rather than spawning a fresh headless one.

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/ev.sock";

my @local_console;      # the browser's OWN handler: Control must CHAIN, not clobber
my $b = EV::WebKit->new(
    window     => [300,200], ephemeral => 1,
    on_console => sub { push @local_console, $_[0] },
);
$b->mock_scheme('ev', sub {
    my $uri = shift;
    return ('<html><body><a id="lnk" href="ev://second">go</a></body></html>', 'text/html')
        if $uri =~ /first/;
    return ('<html><body><h1>SECOND</h1></body></html>', 'text/html');
});
my $ctl = EV::WebKit::Control->listen($b, path => $path);
my $cl  = TCTL->new($path);
$cl->pump(1);           # swallow the hello

sub grab { $cl->wait_event(@_) }

# 1) a navigation the client itself asked for emits BOTH navigate and load
$cl->send_frame({ i => 1, m => 'go', a => ['ev://first'] });
my $nav1 = grab('navigate');
ok($nav1, 'an API navigation reports a navigate event');
is($nav1->{uri}, 'ev://first', '...with the uri');
my $load = grab('load');
ok($load, '...and a load event too');
is($load->{uri}, 'ev://first', '...with the uri');

# 2) navigate: the HUMAN clicks a link. Nothing asked for this -- and before
#    on_navigate the module could not even observe it happening.
$cl->send_frame({ i => 2, m => 'script', a => ['document.getElementById("lnk").click()'] });
my $nav = grab('navigate');
ok($nav, 'a page-initiated navigation reaches the client as an event')
    or diag('the human navigated and the client was never told');
is($nav->{uri}, 'ev://second', '...with the new uri');
# Settle first, and check BOTH buffers. wait_event returns the moment `navigate`
# matches, so a wrongly-emitted load arriving a moment later would not have been
# seen at all -- and pump() is not a settle on its own: it DRAINS {in} and
# returns those frames, while events() reads {events}, which only reply() and
# wait_event() ever fill. Pumping and looking only at events() therefore threw
# the evidence away and passed either way (measured: a spurious load broadcast
# 0.3s after the navigate went undetected). Block 1 above establishes that a
# load does arrive as its own later frame, so 1.5s is long enough to catch one.
# pump(99, ...) not pump(1, ...): pump returns as soon as it has the frames it
# was asked for, so pump(1) collapses on the FIRST thing to arrive. Measured: a
# harmless console event at 0.2s followed by a spurious load at 0.6s went
# undetected with pump(1), and is caught with a count it will not reach.
my @settle = $cl->pump(99, 1.5);
is(scalar(grep { ($_->{ev} // '') eq 'load' } @settle, $cl->events), 0,
    '...and NOT as a load event (nobody asked for this navigation)');

# 3) console: forwarded to the client AND still delivered locally
$cl->send_frame({ i => 3, m => 'script', a => ['console.log("hello")'] });
my $con = grab('console');
ok($con, 'console output reaches the client');
is($con->{text}, 'log: hello', '...with the text');
ok(scalar(grep { /hello/ } @local_console),
    "...and the browser's own on_console still ran (Control chains, it does not clobber)");

# 4) close: a client's quit tells every client the browser is going, BEFORE the
#    socket dies -- so a client can tell an orderly shutdown from a crash.
#    (on_close does not cover this: that fires only when a HUMAN closes the window.)
$cl->send_frame({ i => 4, m => 'quit' });
my $close = grab('close', 10);
ok($close, 'quit over the wire broadcasts a close event before the sockets go');

# 5) The chained handlers live ON THE BROWSER. A closure that captures the
#    browser (or the server) strongly is a cycle plain refcounting can never
#    break -- $b -> on_load -> $b -- and this module has shipped that exact bug
#    more than once. Prove both ends are collectable.
{
    require Scalar::Util;
    my ($wb, $wc);
    {
        my $b2 = EV::WebKit->new(window => [200,150], ephemeral => 1);
        my $c2 = EV::WebKit::Control->listen($b2, path => "$dir/leak.sock");
        Scalar::Util::weaken($wb = $b2);
        Scalar::Util::weaken($wc = $c2);
        ok($wb && $wc, 'setup: browser and server built');
        $c2->close;
        $b2->quit;
    }
    for (1 .. 5) { my $t = EV::timer(0.05, 0, sub { EV::break }); EV::run }
    ok(!defined $wc, 'the server is collectable')
        or diag('something still holds the server -- a chained handler capturing it strongly?');
    ok(!defined $wb, 'and so is the browser')
        or diag('the browser holds the chained handlers, and one of them captures the browser strongly: a cycle');
}

# 6) A pre-existing handler that dies must not cost the clients their event:
#    the browser runs these inside eval, so Control has to broadcast first
{
    my $b_seq = EV::WebKit->new(window => [100,80], ephemeral => 1);
    my @order;
    $b_seq->on_navigate(sub { push @order, 'prev_nav'; die "user nav\n" });
    $b_seq->on_console(sub { push @order, 'prev_con'; die "user con\n" });
    my $ctl_path = "$dir/seq.sock";
    my $ctl_seq = EV::WebKit::Control->listen($b_seq, path => $ctl_path);
    my $cl_seq = TCTL->new($ctl_path);
    $cl_seq->pump(1); # swallow hello
    eval { $b_seq->on_navigate->('about:blank#6') };
    eval { $b_seq->on_console->('test') };
    is_deeply(\@order, ['prev_nav', 'prev_con'], 'prev handlers were called');
    my $nav_ev = $cl_seq->wait_event('navigate', 5);
    ok($nav_ev && $nav_ev->{uri} eq 'about:blank#6', 'navigate broadcast despite a dying handler');
    my $con_ev = $cl_seq->wait_event('console', 5);
    ok($con_ev && $con_ev->{text} eq 'test', 'console broadcast despite a dying handler');
    $cl_seq->close;
    $ctl_seq->close;
    $b_seq->quit;
}

done_testing;
