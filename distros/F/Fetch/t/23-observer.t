#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use File::Spec ();
use Fetch;

# fetch_abi v2: the outbound request observer. `start` fires once per HOP with
# the merged header list still mutable; `done` fires exactly once for each
# start, with the response or the failure.
#
# Registering a C callback is not something Perl can do, so this drives the
# selftest consumer in ft_abi.h: its start callback pushes an X-Fetch-Observer
# header (which the server below echoes back, proving the mutation reached the
# wire) and its done callback counts how each hop ended.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;
my $base = "http://127.0.0.1:$port";

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    # Never hold the harness TAP pipe open, and never outlive the run.
    open STDOUT, ">", File::Spec->devnull();
    open STDERR, ">", File::Spec->devnull();
    alarm 120;
    $SIG{TERM} = sub { exit 0 };
    while (my $c = $srv->accept) {
        my $l = <$c>;
        my ($m, $p) = $l =~ m{^(\S+)\s+(\S+)};
        my %h;
        while (my $line = <$c>) {
            last if $line eq "\r\n";
            $h{lc $1} = $2 if $line =~ /^([^:]+):\s*(.*?)\r\n$/;
        }
        read($c, my $body, $h{'content-length'}) if $h{'content-length'};

        my ($status, $extra, $out) = ('200 OK', '', '');
        if ($p eq '/hop1') { $status = '302 Found'; $extra = "Location: /hop2\r\n" }
        elsif ($p eq '/hop2') { $out = 'landed' }
        elsif ($p eq '/perl') { $out = 'perl:' . ($h{'x-perl-observer'} // '(none)') }
        else { $out = 'seen:' . ($h{'x-fetch-observer'} // '(none)') }

        print $c "HTTP/1.1 $status\r\nContent-Length: " . length($out)
               . "\r\nConnection: close\r\n$extra\r\n$out";
        close $c;
    }
    exit 0;
}
$srv->close;

sub state { return Fetch::_abi_observer_state() }

# ---- nothing registered yet -------------------------------------------------
{
    is(Fetch::_abi_version(), 2, 'fetch_abi is at version 2');
    my ($starts, $dones) = state();
    is($starts, 0, 'no observer has been started');
    is($dones,  0, 'and none finished');
    my $ua = Fetch->new(timeout => 5);
    my $r = $ua->get("$base/plain")->get;
    is($r->content, 'seen:(none)',
        'with no observer registered the request carries no added header');
    (my $s2, my $d2) = state();
    is($s2, 0, 'and still nothing was observed');
}

# ---- register ---------------------------------------------------------------
is(Fetch::_abi_observer_install(), 1,
    'a C consumer registers an outbound observer through the table');

# ---- the added header reaches the wire --------------------------------------
{
    my $ua = Fetch->new(timeout => 5);
    my $r = $ua->get("$base/plain")->get;
    like($r->content, qr/^seen:hop\d+$/,
        'a header pushed by the observer is on the request the server received');

    my ($starts, $dones, $ok, $err) = state();
    is($starts, 1, 'one start for one request');
    is($dones,  1, 'one done for one start');
    is($ok,     1, 'the hop is reported as resolved');
    is($err,    0, 'and not as failed');
}

# ---- a redirect chain is several hops, and each is observed -----------------
{
    my ($s0, $d0) = state();
    my $ua = Fetch->new(timeout => 5);
    my $r = $ua->get("$base/hop1")->get;
    is($r->content, 'landed', 'the redirect was followed');

    my ($s1, $d1, $ok) = state();
    is($s1 - $s0, 2, 'two hops observed for one redirect');
    is($d1 - $d0, 2, 'and both settled');
}

# ---- a failure settles the observer too -------------------------------------
{
    my ($s0, $d0, $ok0, $err0) = state();
    my $ua = Fetch->new(timeout => 2);
    my $r = eval { $ua->get('http://127.0.0.1:1/refused')->get };
    ok(!defined $r, 'a refused connection fails the request');

    my ($s1, $d1, $ok1, $err1) = state();
    is($s1 - $s0, 1, 'the failed hop was started');
    is($d1 - $d0, 1, 'and settled exactly once');
    is($err1 - $err0, 1, 'reported as a failure');
    is($ok1 - $ok0, 0, 'and not as a success');
    isnt($err1, -1, 'the token handed to done matched the one start returned');
}

# ---- the Perl door onto the same registry -----------------------------------
#
# Fetch->on_request takes two coderefs and registers a pair of shims into the
# table the C consumer above is already in, so this also proves the two doors
# coexist: every request below is seen by both.
#
# There is no deregistration - that is the contract, not an oversight - so the
# whole section shares ONE registration and steers it with package variables.

our (@START, @DONE, $DIE);

is(Fetch->on_request(
    sub {
        my ($method, $url, $headers) = @_;
        die "start blew up\n" if $DIE;
        push @$headers, 'X-Perl-Observer' => 'from-perl';
        push @START, { method => $method, url => $url };
        return { url => $url, seq => scalar @START };   # the token: any scalar
    },
    sub {
        my ($token, $res, $err) = @_;
        die "done blew up\n" if $DIE;
        push @DONE, {
            token  => $token,
            status => (defined $err ? undef : $res->status),
            err    => (defined $err ? "$err" : undef),
        };
    },
), 1, 'a Perl consumer registers through Fetch->on_request');

{
    @START = (); @DONE = ();
    my $ua = Fetch->new(timeout => 5);
    my $r = $ua->get("$base/perl")->get;

    is($r->content, 'perl:from-perl',
        'a header pushed from Perl is on the request the server received');
    is(scalar @START, 1, 'start fired once');
    is($START[0]{method}, 'GET', 'with the method');
    like($START[0]{url}, qr{/perl\z}, 'and the url');
    is(scalar @DONE, 1, 'done fired once');
    is($DONE[0]{status}, 200, 'with the response object, whose status reads');
    is($DONE[0]{err}, undef, 'and no error');
    is_deeply($DONE[0]{token}, { url => $START[0]{url}, seq => 1 },
        'the token round-trips as an arbitrary Perl scalar');
}

# both doors saw that request, not one or the other
{
    my ($starts) = state();
    @START = ();
    my $ua = Fetch->new(timeout => 5);
    $ua->get("$base/plain")->get;
    my ($starts2) = state();
    is($starts2 - $starts, 1, 'the C observer still fires');
    is(scalar @START, 1, 'and the Perl one fires for the same request');
}

# per hop, exactly as the C side
{
    @START = (); @DONE = ();
    my $ua = Fetch->new(timeout => 5);
    is($ua->get("$base/hop1")->get->content, 'landed', 'the redirect followed');
    is(scalar @START, 2, 'two hops observed from Perl');
    is(scalar @DONE,  2, 'and both settled');
    is($DONE[0]{status}, 302, 'the first hop reports its redirect');
    is($DONE[1]{status}, 200, 'the second its answer');
}

# a failure reaches done with the error and no response
{
    @START = (); @DONE = ();
    my $ua = Fetch->new(timeout => 2);
    eval { $ua->get('http://127.0.0.1:1/refused')->get };
    is(scalar @START, 1, 'the failed hop started');
    is(scalar @DONE,  1, 'and settled exactly once');
    is($DONE[0]{status}, undef, 'with no response');
    ok(length($DONE[0]{err} // ''), 'and the failure in hand');
}

# An observer is a bystander: C can promise not to croak, Perl cannot, so a
# die is turned into a warning rather than being allowed to fail the request
# it was only watching.
{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, "@_" };
    local $DIE = 1;
    my $ua = Fetch->new(timeout => 5);
    my $r = eval { $ua->get("$base/perl")->get };
    ok($r && $r->status == 200, 'a dying observer does not fail the request');
    is($r->content, 'perl:(none)',
        'the header it never got to push is simply absent');
    is(scalar(grep { /on_request start callback died/ } @warn), 1,
        'the start death was warned');
    is(scalar(grep { /on_request done callback died/ } @warn), 1,
        'and so was the done death');
}

# registration argument checking, in the caller's own frame
{
    my $err = '';
    eval { Fetch->on_request('not a coderef') } or $err = $@;
    like($err, qr/start callback must be a code reference/,
        'a non-coderef start croaks at registration');
    $err = '';
    eval { Fetch->on_request(sub { }, 'nope') } or $err = $@;
    like($err, qr/done callback must be a code reference/,
        'and so does a non-coderef done');
    is(Fetch->on_request(sub { }), 1, 'the done callback is optional');
}

# ---- the Perl door onto the same registry -----------------------------------
{
    my @log;
    is(Fetch->on_request(
        sub { my ($m, $u, $h) = @_;
              push @$h, 'X-Perl-Observer' => 'yes';
              return { method => $m, url => $u } },
        sub { my ($tok, $res, $err) = @_;
              push @log, [ $tok->{method}, $tok->{url},
                           $err ? 'ERR' : $res->status ] },
    ), 1, 'Fetch->on_request registers a Perl observer');

    my $ua = Fetch->new(timeout => 5);
    my $r = $ua->get("$base/plain")->get;
    like($r->content, qr/^seen:hop\d+$/,
        'the C observer is still on the same request');

    is(scalar @log, 1, 'the Perl observer saw one hop');
    is($log[0][0], 'GET', 'it was told the method');
    is($log[0][1], "$base/plain", 'and the url');
    is($log[0][2], 200, 'and the status the request ended with');

    @log = ();
    eval { $ua->get('http://127.0.0.1:1/refused')->get };
    is(scalar @log, 1, 'a failure reaches the Perl observer too');
    is($log[0][2], 'ERR', 'reported as a failure, not a status');
}

# ---- a broken observer must not break the request ---------------------------
{
    is(Fetch->on_request(sub { die "observer is broken\n" }), 1,
        'a dying observer registers like any other');

    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    my $ua = Fetch->new(timeout => 5);
    my $r = eval { $ua->get("$base/plain")->get };

    ok($r && $r->is_success,
        'the request still succeeds: an observer is a bystander');
    ok(scalar(grep { /on_request start callback died/ } @warn),
        'and the death became a warning naming which half died');
}

# ---- registration-time mistakes croak in the caller's frame -----------------
{
    ok(!eval { Fetch->on_request('not a coderef'); 1 },
        'a non-coderef start croaks');
    like($@, qr/must be a code reference/, 'with a clear message');
    ok(!eval { Fetch->on_request(sub {}, 'not a coderef'); 1 },
        'a non-coderef done croaks too');
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
