package EV::WebKit::Client;
use v5.10;
use strict;
use warnings;

use Carp ();
use Errno ();
use Scalar::Util ();
use IO::Socket::UNIX ();   # () like every other import here: its Socket re-exports would otherwise land in this package as callable methods
use MIME::Base64 ();
use EV::WebKit::Protocol;
use EV::WebKit::Client::Element;

our $VERSION = '0.04';

# How many undelivered broadcast events to keep when no on_event handler was
# given. A page produces console output at its own pace and a caller may never
# call events(); this bounds what that costs in the caller's process.
use constant MAX_EVENT_BACKLOG => 10_000;

# Strip the " at FILE line N." a croak adds, so an error delivered to a callback
# reads like every other error this API produces.
sub _clean { my $e = shift // ''; $e =~ s/ at \S+ line \d+\.?\s*$//; $e }

# Deliver a failure on a clean tick, never on the caller's own stack. EV::WebKit
# defers every callback for the same reason: delivered inline, the ordinary
# retry-on-error shape (`$c->title(sub { $retry->() if $_[1] })`) recurses
# instead of looping, and code after the call has not run yet when the callback
# depending on it fires. The timer is held by its own closure -- a void-context
# watcher is collected before it fires.
sub _defer_err {
    my ($self, $cb, $err) = @_;
    my $t; $t = EV::timer(0, 0, sub { undef $t; _deliver($cb, undef, $err) });
    return;
}

# Drive a browser running in another process.
#
# Blocking by default -- `say $c->title` -- which is what you want from a shell
# or a one-off script. Blocking mode is PLAIN SOCKET I/O, deliberately not a
# nested EV::run: a nested loop inside a callback is how EV::Glib gets wedged,
# and a client has no business running somebody else's loop anyway.
#
# With `ev => 1` every method takes a trailing callback instead and behaves like
# EV::WebKit itself, so code moves between a local browser and a remote one
# without being rewritten.

# The browser methods, forwarded verbatim.
#
# NOT here: find, find_all, find_js, find_all_js and wait_for (all resolve with an element, so
# they are wrapped into a proxy), and screenshot (bytes mode comes back base64'd
# and has to be decoded). They are defined separately below -- and they must not
# appear here as well, because this loop assigns the globs at RUNTIME and would
# quietly clobber them.
my @METHODS = qw(
    go load_html back forward reload stop
    can_go_back can_go_forward uri title is_loading html status
    script script_async pdf
    press scroll download wait_for_js frames resize zoom wait_for_navigation
    settings set_user_agent user_agent set_proxy show_devtools
    set_cookie cookies clear_cookies save_cookies load_cookies
    quit
);

sub connect {
    my ($class, $path) = (shift, shift);
    Carp::croak('connect: a socket path is required') unless defined $path && length $path;
    # Before %o = @_: an odd list warns from inside this file and drops the
    # trailing token, so connect($path, 'ev') built a BLOCKING client with `ev`
    # unset -- and the first call from inside the caller's loop then blocks it.
    Carp::croak('connect: options must be name => value pairs') if @_ % 2;
    my %o = @_;
    if (my @bad = sort grep { !/^(?:ev|on_event)$/ } keys %o) {
        Carp::croak("connect: unknown option(s): @bad (expected ev/on_event)");
    }
    Carp::croak('connect: on_event must be a code reference')
        if defined $o{on_event} && ref $o{on_event} ne 'CODE';
    my $sock = IO::Socket::UNIX->new(Peer => $path)
        or Carp::croak("connect: cannot connect to '$path': $!");

    my $self = bless {
        sock     => $sock,
        path     => $path,
        dec      => EV::WebKit::Protocol::decoder(),
        next_id  => 0,
        events   => [],
        pending  => {},                 # ev mode: id => callback
        stash    => {},                 # blocking: somebody else's answer, read while we waited
        out      => '',                 # ev mode: queued outbound octets
        on_event => $o{on_event},
        ev       => $o{ev} ? 1 : 0,
        hello    => undef,
    }, $class;

    if ($self->{ev}) {
        # EV is loaded only for ev mode -- a blocking client is plain socket I/O
        # and has no business pulling in an event loop. Hence EV::READ() with
        # parens: a bareword would have to resolve at compile time, and EV is not
        # loaded then.
        require EV;
        $sock->blocking(0);
        # WEAK, like every other self-stored watcher in this distribution: the
        # watcher lives on $self and its closure captured $self, so an ev client
        # the caller simply dropped was never collected -- DESTROY never ran, the
        # socket stayed open, and anything in flight at that moment was never
        # resolved. A daemon that attaches one client per job leaked an fd each
        # time.
        Scalar::Util::weaken(my $wself = $self);
        $self->{rw} = EV::io($sock, EV::READ(), sub { my $s = $wself or return; $s->_ev_readable });
    }
    else {
        # The greeting tells a client attaching to a long-lived session where the
        # browser already is. Read it now so ->hello is available immediately.
        $self->{hello} = $self->_read_until(sub { ($_[0]{ev} // '') eq 'hello' });
    }

    return $self;
}

sub path  { $_[0]{path} }
sub hello { $_[0]{hello} }

# Drain the events that have arrived (blocking mode buffers them; ev mode
# delivers them to on_event instead).
sub events {
    my $self = shift;
    my @e = @{ $self->{events} };
    $self->{events} = [];
    return @e;
}

sub disconnect {
    my $self = shift;
    delete $self->{rw};
    delete $self->{ww};
    close $self->{sock} if $self->{sock};
    delete $self->{sock};
    # Anything still in flight is owed an answer. Walking away from a pending
    # callback is a hung caller -- and disconnect() is an ordinary, documented
    # call, not an error path, so it is if anything the likelier way to get here.
    my @owed = values %{ $self->{pending} || {} };
    $self->{pending} = {};
    _deliver($_, undef, 'disconnected') for @owed;
    return;
}

sub DESTROY { local $@; eval { $_[0]->disconnect } }

# ---------------------------------------------------------------- plumbing

sub _write {
    my ($self, $octets) = @_;
    my $sock = $self->{sock} or Carp::croak('the connection is closed');

    if ($self->{ev}) {
        # Non-blocking. Queue it and let a write watcher drain it: spinning on
        # EAGAIN would burn a whole core AND block the caller's entire loop --
        # and an ev-mode call is supposed to return immediately. (The server's
        # own _flush already does exactly this; the client did not.)
        $self->{out} .= $octets;
        return $self->_flush;
    }

    # Writing to a peer that has closed raises SIGPIPE, whose default is to KILL
    # THE PROCESS -- so one call after the browser has gone would end the client
    # outright, and no eval can catch a signal. Ignore it and let syswrite report
    # EPIPE like any other error.
    local $SIG{PIPE} = 'IGNORE';
    while (length $octets) {
        my $n = syswrite($sock, $octets);
        if (!defined $n) {
            next if $!{EINTR} || $!{EAGAIN};
            Carp::croak("write failed: $!");
        }
        substr($octets, 0, $n, '');
    }
    return;
}

sub _flush {
    my $self = shift;
    my $sock = $self->{sock} or return;
    local $SIG{PIPE} = 'IGNORE';
    while (length $self->{out}) {
        my $n = syswrite($sock, $self->{out});
        if (!defined $n) {
            last if $!{EAGAIN} || $!{EINTR};
            return $self->_ev_gone("write failed: $!");
        }
        substr($self->{out}, 0, $n, '');
    }
    if (length $self->{out}) {
        Scalar::Util::weaken(my $wself = $self);
        $self->{ww} ||= EV::io($sock, EV::WRITE(), sub { my $s = $wself or return; $s->_flush });
    }
    else {
        delete $self->{ww};
    }
    return;
}

sub _event {
    my ($self, $f) = @_;
    # The greeting is an event, but it is also the answer to "where is this
    # browser?" -- keep it, in ev mode too, or ->hello is undef forever and
    # re-attaching to a long-lived session cannot work.
    $self->{hello} = $f if ($f->{ev} // '') eq 'hello' && !$self->{hello};
    if (my $cb = $self->{on_event}) {
        # Guarded: a throwing event handler must not take down whatever else is
        # being delivered in the same batch.
        unless (eval { $cb->($f->{ev}, $f); 1 }) {
            warn "EV::WebKit::Client: on_event callback died: $@";
        }
        return;
    }
    # Bounded, for the same reason the server bounds its per-client outbound
    # queue: a page generates console lines as fast as it likes, and a client
    # that never drains events() must not grow without limit inside the caller's
    # own process. Oldest first, which is what a caller watching for "what just
    # happened" wants kept.
    push @{ $self->{events} }, $f;
    shift @{ $self->{events} } while @{ $self->{events} } > MAX_EVENT_BACKLOG;
    return;
}

# Blocking: read frames until $want->($frame) says one of them is the one we are
# after. Events met on the way are dispatched, never confused with a response.
sub _read_until {
    my ($self, $want) = @_;
    my $sock = $self->{sock} or Carp::croak('the connection is closed');
    while (1) {
        # Check the stash EVERY iteration, not just once. on_event is invoked
        # from inside this loop, and a handler that makes its own blocking call
        # nests a second _read_until that reads -- and stashes -- the OUTER
        # call's answer while we were parked in sysread. So our answer can appear
        # in the stash between reads; binning it, or checking only at entry,
        # leaves the outer caller waiting forever for a response already in hand.
        for my $sid (sort { $a <=> $b } keys %{ $self->{stash} }) {
            my $f = $self->{stash}{$sid};
            if ($want->($f)) { delete $self->{stash}{$sid}; return $f }
        }
        my $n = sysread($sock, my $buf, 65536);
        if (!defined $n) {
            next if $!{EAGAIN} || $!{EINTR};
            Carp::croak("read failed: $!");
        }
        Carp::croak('the browser closed the connection') unless $n;
        # Drain the WHOLE batch before returning. One read can decode several
        # frames, and returning on the first match would silently drop the rest --
        # exactly the reentrancy hang: a nested call reads its own answer AND the
        # outer call's in one batch, and abandoning the batch loses the outer's,
        # which was already pulled out of the decoder. So keep our match aside and
        # finish draining: events get dispatched, other answers get stashed for
        # whoever is waiting, and only then do we return.
        my ($mine, $got_mine);
        for my $f ($self->{dec}->($buf)) {
            # The predicate goes FIRST, before the event branch: the frame we are
            # waiting for can itself BE an event -- the hello is one -- and
            # dispatching it as an event would mean losing the very thing we want.
            # The codec gives up permanently on an oversized line (see
            # EV::WebKit::Protocol) and reports it as {_bad}. Nothing further
            # can ever be decoded on this connection, so surface it as the
            # answer rather than letting every call from here on quietly return
            # undef with no error -- which is what happened while this frame
            # shape went unrecognised.
            if (defined $f->{_bad}) { $mine = { e => "protocol error: $f->{_bad}" }; $got_mine = 1; next }
            if (!$got_mine && $want->($f)) { $mine = $f; $got_mine = 1; next }
            if (defined $f->{ev}) { $self->_event($f); next }
            # A null-id error (a malformed line) answers no particular request; if
            # nothing else here is ours, it belongs to whoever is waiting.
            if (!defined $f->{i}) { $mine //= $f; $got_mine ||= 1; next }
            $self->{stash}{ $f->{i} } = $f;    # somebody else's answer -- keep it
        }
        return $mine if $got_mine;
    }
}

# ---------------------------------------------------------------- calls

sub _next_id { ++$_[0]{next_id} }

# One request. In blocking mode this returns the result and CROAKS on error --
# synchronous code has no callback to hand an error to, and croaking is how it
# reports one. In ev mode the last argument is a callback and it gets
# ($result, $err), exactly as EV::WebKit does.
sub _request {
    my ($self, $m, $a, $h, $cb, $post) = @_;
    my $id = $self->_next_id;
    my %frame = (i => $id, m => $m, a => $a);
    $frame{h} = $h if defined $h;

    if ($self->{ev}) {
        Carp::croak("$m: a callback is required in ev mode (it cannot block: you own the loop)")
            unless $cb;
        # Encode before registering, and undo the registration if the write
        # fails -- either way a failure of the two is DELIVERED to the callback. Both can croak on a healthy connection (an argument the
        # JSON codec cannot represent) or a dead one, and an ev-mode call is
        # nearly always made from inside another callback -- where the croak is
        # swallowed by $EV::DIED and the just-registered entry would sit in
        # {pending} forever, never called. This is the one contract this mode
        # has: an error is DELIVERED, never thrown.
        my $line = eval { EV::WebKit::Protocol::encode(\%frame) };
        return $self->_defer_err($cb, "$m: " . _clean($@)) unless defined $line;
        my $wrapped = sub {
            my ($r, $e) = @_;
            return $cb->(undef, $e) if defined $e;
            return $cb->($post ? $post->($r) : $r, undef);
        };
        $self->{pending}{$id} = $wrapped;
        unless (eval { $self->_write($line); 1 }) {
            delete $self->{pending}{$id};
            return $self->_defer_err($cb, "$m: " . _clean($@));
        }
        return;
    }

    $self->_write(EV::WebKit::Protocol::encode(\%frame));
    my $f = $self->_read_until(sub { defined $_[0]{i} && $_[0]{i} == $id });
    Carp::croak("$m: $f->{e}") if defined $f->{e};
    return $post ? $post->($f->{r}) : $f->{r};
}

sub _call {
    my ($s, $m, $a, $h) = (shift, shift, shift, shift);
    my $cb = _cb($a);
    $s->_no_cb_in_blocking_mode($m, $cb);
    $s->_request($m, $a, $h, $cb);
}
sub _call_el {
    my ($s, $m, $a, $h) = (shift, shift, shift, shift);
    my $cb = _cb($a);
    $s->_no_cb_in_blocking_mode($m, $cb);
    # WEAK, like the watchers: this closure is reachable from {pending} and
    # captured $s, so an ev client dropped with an element-returning request in
    # flight was not collected until the answer came back -- which for a
    # wait_for could be an hour.
    Scalar::Util::weaken(my $ws = $s);
    $s->_request($m, $a, $h, $cb, sub { my $c = $ws or return undef; $c->_wrap($_[0]) });
}

# Blocking mode returns its result; a trailing callback there is a caller who
# meant to open the client with ev => 1, and silently never running it is the
# worst of the three possible answers.
sub _no_cb_in_blocking_mode {
    my ($s, $m, $cb) = @_;
    Carp::croak("$m: a callback needs ev => 1 (this client is in blocking mode, which returns the result)")
        if $cb && !$s->{ev};
    return;
}

# In ev mode the caller's callback is the last argument they passed; strip it out
# of the wire arguments.
sub _cb {
    my $a = shift;
    return undef unless @$a && ref $a->[-1] eq 'CODE';
    # ...but not when it is the VALUE of a named callback option. scroll takes
    # `cb => $cb` as well as a trailing one, so popping blindly left the orphan
    # key travelling alone; the server then appended its own `cb =>`, the method
    # saw an odd option list, and the documented spelling croaked remotely while
    # working locally. Pull the pair out instead, and send it as a trailing
    # callback, which is what the wire carries.
    if (@$a >= 2 && defined $a->[-2] && !ref $a->[-2]
        && ($a->[-2] eq 'cb' || $a->[-2] eq 'callback')) {
        my $c = pop @$a;
        pop @$a;
        return $c;
    }
    return pop @$a;
}

# A handle (or a list of them) becomes an element proxy.
sub _wrap {
    my ($self, $r) = @_;
    return undef unless defined $r;
    return [ map { EV::WebKit::Client::Element->_new($self, $_->{h}) } @$r ] if ref $r eq 'ARRAY';
    # wait_for(gone => 1) resolves with a plain TRUE, not a handle -- there is
    # no node left to hand back. The server stopped marshalling it as one; this
    # is the other half. Without it `1->{h}` dies under strict refs: in blocking
    # mode that raw error replaces the answer, and in ev mode _deliver's eval
    # swallows it and the caller's callback is never invoked at all.
    return $r unless ref $r;
    return EV::WebKit::Client::Element->_new($self, $r->{h});
}

# Raw bytes cannot live in a JSON string, so screenshot({ bytes => 1 }) comes back
# base64'd. Decode it here, so a caller gets the same raw PNG octets they would
# get from EV::WebKit itself -- the whole point being that code moves between a
# local browser and a remote one without being rewritten.
sub _unb64 {
    my (undef, $r) = @_;
    return $r unless ref $r eq 'HASH' && exists $r->{b64};
    return MIME::Base64::decode_base64($r->{b64});
}

sub _ev_readable {
    my $self = shift;
    my $sock = $self->{sock} or return;
    my $n = sysread($sock, my $buf, 65536);
    if (!defined $n) { return if $!{EAGAIN} || $!{EINTR}; return $self->_ev_gone("read failed: $!") }
    return $self->_ev_gone('the browser closed the connection') unless $n;
    for my $f ($self->{dec}->($buf)) {
        # A dead codec cannot produce another frame, so every pending callback
        # is owed an error now -- otherwise they are simply never called, and
        # the caller's EV::run waits for answers that can no longer arrive.
        return $self->_ev_gone("protocol error: $f->{_bad}") if defined $f->{_bad};
        if (defined $f->{ev}) { $self->_event($f); next }
        my $cb = delete $self->{pending}{ $f->{i} // '' } or next;
        _deliver($cb, $f->{r}, $f->{e});
    }
    return;
}

# Deliver one callback, guarded. Several responses can arrive in a single read,
# and a die from one of them must not swallow the rest of the batch -- the caller
# would never hear about requests it is still waiting on. (The same lesson the
# browser's own quit() flush loops taught.)
sub _deliver {
    my ($cb, @args) = @_;
    return if eval { $cb->(@args); 1 };
    warn "EV::WebKit::Client: callback died: $@";
    return;
}

# The far end went away. Every request still in flight is owed an answer -- a
# dropped callback is a hung caller, which is the one failure mode this protocol
# must not have.
sub _ev_gone {
    my ($self, $why) = @_;
    my @owed = values %{ $self->{pending} };
    $self->{pending} = {};
    $self->disconnect;
    # On a clean tick, never on the caller's stack. A socket that died unnoticed
    # is discovered inside _write, so delivering here ran the new request's
    # callback -- and every earlier one still in flight -- before the method the
    # caller just invoked had returned.
    my $t; $t = EV::timer(0, 0, sub { undef $t; _deliver($_, undef, $why) for @owed });
    return;
}

# ---------------------------------------------------------------- the API

for my $m (@METHODS) {
    no strict 'refs';
    *{__PACKAGE__ . "::$m"} = sub {
        my $self = shift;
        return $self->_call($m, [@_]);
    };
}

# All of these resolve with an element.
for my $m (qw(find find_all find_js find_all_js wait_for)) {
    no strict 'refs';
    *{__PACKAGE__ . "::$m"} = sub {
        my $self = shift;
        return $self->_call_el($m, [@_]);
    };
}

# bytes mode comes back base64'd; give the caller the raw octets.
sub screenshot {
    my $self = shift;
    my $a    = [@_];
    my $cb   = _cb($a);
    $self->_no_cb_in_blocking_mode('screenshot', $cb);
    Scalar::Util::weaken(my $ws = $self);
    return $self->_request('screenshot', $a, undef, $cb, sub { my $c = $ws or return undef; $c->_unb64($_[0]) });
}

1;

__END__

=head1 NAME

EV::WebKit::Client - drive an EV::WebKit browser running in another process

=head1 SYNOPSIS

Blocking, which is what you want from a shell or a one-off script:

    use v5.10;                 # for say(), as the eg/ scripts do
    use EV::WebKit::Client;

    my $c = EV::WebKit::Client->connect("$ENV{XDG_RUNTIME_DIR}/evwk.sock");
    say 'attached to: ', $c->hello->{uri} // '(nothing loaded)';

    $c->go('https://example.com');
    say $c->title;

    my $el = $c->find('h1');
    say $el->text;

Or EV-native, which is what you want inside an event loop:

    use v5.10;                 # for say(), as above
    use EV;                    # the blocking form above does not need this
    use EV::WebKit::Client;

    my $c = EV::WebKit::Client->connect($path, ev => 1, on_event => sub {
        my ($ev, $data) = @_;
        say "the browser navigated to $data->{uri}" if $ev eq 'navigate';
    });

    $c->go('https://example.com', sub {
        my (undef, $err) = @_;
        # ev mode delivers errors here; a die would only reach $EV::DIED
        if ($err) { warn "navigation failed: $err\n"; return EV::break }
        $c->title(sub { say $_[0] });
    });

    EV::run;

=head1 DESCRIPTION

The other half of L<EV::WebKit::Control>. The L<EV::WebKit> methods listed under
L</METHODS> are here, with the same name and the same arguments. That is the
page-driving surface, not the whole class: whatever configures an instance
locally -- the user script and style methods, the C<on_*> handler accessors, the
fingerprint accessors -- stays with the process that owns the browser, since
those either take a Perl callback or describe how that instance was built.

=head2 Blocking mode (the default)

A method with no callback blocks and returns the result. Errors are B<croaked>,
carrying the browser's own error string: synchronous code has no callback to
hand an error to, and croaking is how it reports one.

    my $title = eval { $c->title };
    warn "the browser is gone: $@" if $@;

Blocking mode is plain socket I/O -- deliberately B<not> a nested C<EV::run>. A
nested loop inside a callback is how EV::Glib gets wedged, and a client has no
business running somebody else's event loop.

A trailing callback in this mode B<croaks>. Blocking calls return their result,
so a callback there is a caller who meant C<< ev => 1 >>, and running it is not
an option this mode has -- saying nothing would silently skip every continuation
while the calls appeared to succeed.

Events that arrive while you are waiting are collected. Drain them with
C<events>, or hand C<connect> an C<on_event> callback. That applies to B<both>
modes: an ev-mode client built without C<on_event> buffers them exactly as a
blocking one does.

What is buffered is bounded. A page produces console output at its own pace, so
a client that never drains would otherwise grow without limit inside your
process: at most 10,000 undelivered events are kept, oldest discarded first. An
C<on_event> handler never loses one, since nothing is buffered for it. The
browser side is bounded the same way and for the same reason -- see
L<EV::WebKit::Control/"SECURITY">.

=head2 EV mode

    my $c = EV::WebKit::Client->connect($path, ev => 1);

Every method now takes a trailing callback and returns immediately; the callback
gets C<($result, $err)>, exactly as C<EV::WebKit> does -- so code moves between a
local browser and a remote one without being rewritten. Calling a method without
a callback in this mode croaks: it cannot block, because you own the loop.

If the browser goes away, every request still in flight is answered with an error
rather than dropped. A dropped callback is a hung caller.

=head1 METHODS

C<connect>, C<hello> (the greeting frame: where the browser already was when you
attached), C<events>, C<path> (the socket this client is attached to),
C<disconnect>, plus every C<EV::WebKit> method:
C<go>, C<load_html>, C<back>, C<forward>, C<reload>, C<stop>, C<can_go_back>,
C<can_go_forward>, C<uri>, C<title>, C<is_loading>, C<status>, C<html>,
C<script>, C<script_async>, C<find>, C<find_all>, C<find_js>, C<find_all_js>,
C<wait_for>, C<wait_for_js>, C<wait_for_navigation>,
C<press>, C<scroll>, C<screenshot>, C<pdf>, C<download>, C<frames>, C<resize>,
C<zoom>,
C<settings>, C<set_user_agent>, C<user_agent>, C<set_proxy>, C<show_devtools>,
C<set_cookie>, C<cookies>, C<clear_cookies>, C<save_cookies>, C<load_cookies>,
C<quit>.

C<mock_scheme> is not available remotely: its argument is a Perl callback that
WebKit invokes inside the browser process, and there is nothing to send.

=head1 SEE ALSO

L<EV::WebKit::Control>, L<EV::WebKit>, L<EV::WebKit::Client::Element>.

=cut
