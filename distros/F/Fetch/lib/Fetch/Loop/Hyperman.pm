package Fetch::Loop::Hyperman;

use strict;
use warnings;

our $VERSION = '0.15';

use parent -norequire, 'Fetch::Loop';
use Fetch::Loop ();
use Time::HiRes ();

sub new {
    my ($class, $loop) = @_;
    $loop ||= do { require Hyperman::Loop; Hyperman::Loop->new };
    return bless { loop => $loop, fd => {} }, $class;
}

sub loop { $_[0]{loop} }

sub _ft_arm {
    my ($self, $fd, $mask, $cv) = @_;
    my $loop = $self->{loop};
    my $st   = $self->{fd}{$fd};

    if (!$mask) {
        if ($st) {
            $loop->unwatch_io($st->{r}) if $st->{r};
            $loop->unwatch_io($st->{w}) if $st->{w};
            delete $self->{fd}{$fd};
        }
        return;
    }

    $st ||= $self->{fd}{$fd} = {};

    if ($mask & Fetch::Loop::FT_READ) {
        $st->{r} ||= $loop->watch_io($fd, 'r', sub { $cv->() });
    } elsif ($st->{r}) {
        $loop->unwatch_io(delete $st->{r});
    }
    if ($mask & Fetch::Loop::FT_WRITE) {
        $st->{w} ||= $loop->watch_io($fd, 'w', sub { $cv->() });
    } elsif ($st->{w}) {
        $loop->unwatch_io(delete $st->{w});
    }
    return;
}

# Per-request deadlines are not armed as one kernel timer each: under load that
# is two hot paths at once - a kevent syscall to arm every request, and (since a
# normally-completing request only marks its timer cancelled) a kqueue that
# accumulates one live ~timeout-long timer per request. Instead we keep the
# pending deadlines in a plain list and run a SINGLE coarse repeating timer that
# sweeps it, firing whatever is due. One kernel timer total, re-armed only while
# deadlines are outstanding, so an idle loop stops ticking. The cost is up to
# SWEEP granularity of slack before a timeout fires - immaterial for the
# second(s)-scale request timeouts this exists to enforce.
use constant _SWEEP => 0.1;    # sweep granularity (seconds)

sub _ft_timer {
    my ($self, $secs, $cv) = @_;
    my $g = { at => Time::HiRes::time() + $secs, cv => $cv, cancelled => 0 };
    push @{ $self->{timers} }, $g;
    unless ($self->{sweeping}) {
        $self->{sweeping} = 1;
        $self->_arm_sweep;
    }
    return $g;
}

sub _ft_untimer {
    my ($self, $g) = @_;
    $g->{cancelled} = 1 if ref $g;
    return;
}

sub _arm_sweep {
    my ($self) = @_;
    $self->{loop}->timer(_SWEEP, sub { $self->_sweep });
    return;
}

sub _sweep {
    my ($self) = @_;
    my $now = Time::HiRes::time();
    my $due = delete $self->{timers} || [];
    $self->{timers} = [];       # a fired timeout may enqueue a fresh request
    for my $g (@$due) {
        next if $g->{cancelled};
        if ($g->{at} <= $now) { $g->{cancelled} = 1; $g->{cv}->() }
        else                  { push @{ $self->{timers} }, $g }
    }
    if (@{ $self->{timers} }) { $self->_arm_sweep }
    else                      { $self->{sweeping} = 0 }
    return;
}

sub _ft_await {
    my ($self, $f) = @_;
    return if $f->is_ready;
    my $loop = $self->{loop};
    $f->on_ready(sub { $loop->stop });
    $loop->run;
    return;
}

sub install_await {
    my ($self) = @_;
    $Fetch::Future::AWAIT = sub { $self->_ft_await($_[0]) };
    return $self;
}

1;

__END__

=head1 NAME

Fetch::Loop::Hyperman - run Fetch on a Hyperman::Loop

=head1 SYNOPSIS

    use Fetch;

    # inside a Hyperman worker: share the worker's own loop
    my $ua = Fetch->new(loop => Hyperman->loop);
    my $f  = $ua->get('https://upstream/api');
    my $res = $f->get;   # awaits without blocking the worker's other conns

=head1 DESCRIPTION

Adapts a L<Hyperman::Loop> - the per-worker event loop at the core of
L<Hyperman> - so Fetch's client requests run on the same loop that is serving
inbound connections. This is the natural pairing: a Hyperman app making
outbound HTTP/2 calls with the same non-blocking machinery it serves with.
Pass a raw C<Hyperman::Loop> as C<< Fetch->new(loop => ...) >> and it is
wrapped automatically.

Since Fetch 0.10 (with Hyperman 0.10+) the wrapping is mostly ceremonial:
Fetch drives the loop directly through Hyperman's public B<C ABI> (resolved
at runtime via C<Hyperman::_abi_ptr>; see "C ABI" in L<Hyperman>). Socket
readiness reaches Fetch's connection state machine with no Perl call frame,
interest changes skip the C<_ft_arm> method dispatch below, and per-request
deadlines are precise one-shot kernel timers armed and cancelled in C rather
than entries in this adapter's 0.1s sweep list. The Perl methods in this
class remain as the fallback when the running Hyperman predates its C ABI,
and as the reference implementation of the adapter seam.

=head2 new([$hyperman_loop])

Wrap the given loop, or make a fresh C<< Hyperman::Loop->new >>.

=head2 loop

The underlying C<Hyperman::Loop>.

=head2 install_await

Install C<$Fetch::Future::AWAIT> so a bare C<< $future->get >> pumps the loop
(C<run> until the future readies, then C<stop>). Because Hyperman's C<run> is
re-entrant, awaiting from inside a running worker services other connections
instead of blocking them.

With Hyperman's C ABI available (0.10+), Fetch replaces this hook with a C
closure at UA construction: the awaited future is bridged to a native
Hyperman::Future and the loop pumped with the ABI's C<run_until>. Besides
skipping the Perl dispatch, that retires the C<stop> flag - a nested await
returns exactly when its own future readies rather than stopping whichever
C<run> happens to be innermost. This Perl version remains as the fallback.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
