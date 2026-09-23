package TeardownAudit;

use strict;
use warnings;

# Loaded with -M before the test, so this END block registers first and
# therefore runs last -- after EV::Telegram::TDLib's own END has sent its
# closes. What survives to here is what TDLib would still be holding when
# its statics are torn down.
#
# TDLib performs no client teardown once exit has begun (Client.cpp: ~Impl
# returns early on ExitGuard::is_exited), and ~MultiImpl then detaches its
# scheduler thread instead of joining it before calling finish() -- so a
# client left materialised at exit is a genuine race, not a tidy leak.
#
# An id that never carried a request is inert: tdjson only creates a client
# on its first request, so a reserved-only id has no MultiImpl behind it.

my %materialised;   # client_id => 1, once a real request was sent to it
my %close_sent;     # client_id => 1, once a close was sent to it
my %closed;         # client_id => 1, once TDLib answered with Closed

sub import {
    my $target = 'EV::Telegram::TDLib';
    require EV::Telegram::TDLib;

    my $send = $target->can('_send') or die "no _send to hook";
    no warnings 'redefine';
    no strict 'refs';
    *{"${target}::_send"} = sub {
        my ($cid, $json) = @_;
        # a test that stubs _send itself replaces this hook; that is fine,
        # because nothing then reaches TDLib and the id stays unmaterialised
        if (defined $cid) {
            $materialised{$cid} = 1;
            $close_sent{$cid} = 1 if $json && $json =~ /"\@type"\s*:\s*"close"/;
        }
        return $send->(@_);
    };

    # A sent close is not a completed one, and the difference is the whole
    # hazard: the shutdown pump can run out of budget with every close issued
    # and none of them answered, which this audit used to score as clean.
    # Only authorizationStateClosed coming back means TDLib let the client go.
    my $dispatch = $target->can('dispatch_raw') or die "no dispatch_raw";
    *{"${target}::dispatch_raw"} = sub {
        my ($cid, $json) = @_;
        $closed{$cid} = 1
            if defined $cid && defined $json
            && $json =~ /"authorizationStateClosed"/;
        return $dispatch->(@_);
    };
    # the XS side was handed a code ref at load time, so redefining the glob
    # above changes nothing for real traffic from the reader thread: it still
    # holds the original CV. Re-register so the wrapper is what it calls.
    $target->can('_set_dispatch')->(\&{"${target}::dispatch_raw"});
}

END {
    # LIVE: TDLib still holds it and no teardown was even attempted.
    # STRANDED: a close was sent and TDLib never answered it -- the weaker
    # failure the old "a close was sent" oracle scored as clean.
    my @live = sort { $a <=> $b } grep { !$close_sent{$_} } keys %materialised;
    my @stranded = sort { $a <=> $b }
                   grep { $close_sent{$_} && !$closed{$_} } keys %materialised;
    print STDERR "TEARDOWN-AUDIT-STRANDED: @stranded\n" if @stranded;
    # printed, not died: this runs during global destruction. The DONE line
    # is unconditional so the caller can tell a clean run from one where this
    # block never ran at all -- a child that died early, or a module that
    # failed to load, otherwise looks exactly like a pass.
    print STDERR "TEARDOWN-AUDIT-LIVE: @live\n" if @live;
    print STDERR "TEARDOWN-AUDIT-DONE\n";
}

1;
