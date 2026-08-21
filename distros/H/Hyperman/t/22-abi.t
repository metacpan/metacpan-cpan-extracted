#!perl
use strict;
use warnings;
use Test::More;
use Hyperman;

# The public C ABI (include/hyperman/hm_abi.h): the versioned function-pointer
# table reached through Hyperman::_abi_ptr, and the EU::Depends provider
# config that lets a consumer (e.g. DBIx::Loop) find the header without
# copying it.

# _abi_ptr returns the address of the process-wide table. It is an IV carrying
# a raw pointer, so it may legitimately be negative - Solaris x86-64 maps shared
# objects around 0xFFFFFC7F..., which sets the sign bit. INT2PTR round-trips the
# bits either way; what matters is that it is non-zero and stable, and
# _abi_selftest below is what proves the table actually works.
my $ptr = Hyperman::_abi_ptr();
ok(defined $ptr && $ptr != 0, "_abi_ptr returns a table address ($ptr)");
is(Hyperman::_abi_ptr(), $ptr, 'the table is static - same address');

# _abi_selftest resolves the table in C and drives every entry: future
# lifecycle (done/fail/on_ready, double-settle no-op), a C io watcher on a
# pipe, a cancelled timer, and a live timer, pumped with run_until.
is(Hyperman::_abi_selftest(), 1,
   '_abi_selftest: loop, watchers, timers and futures through the ABI table');

# The table only ever grows at the tail, so a consumer compiled against an
# older header keeps working: existing entries never move. The selftest
# above also exercises the v2 conn_detach entry's rejection path (a ticket
# naming no connection); t/23-detach.t covers the success path live. It also
# drives the v3 abuse controls (deny_check/add/remove and a fixed-window
# ratelimit_hit) against the shared arena.
is(Hyperman::_abi_version(), 5,
   'ABI version 5 (v2 conn_detach, v3 denylist + rate limit, v4 worker start, '
 . 'v5 the cross-worker message bus)');

# v4 on_worker_start registers here; that it actually FIRES, once per worker
# and after the fork, is t/33-worker-start.t, which needs a live server.
is(Hyperman::_abi_worker_hook_install(), 1,
   'v4 on_worker_start accepts a registration through the table');

# Provider config: ExtUtils::Depends wrote Hyperman::Install::Files with an
# include path, so a dependent's ExtUtils::Depends->new(..., 'Hyperman')
# picks up hm_abi.h with no vendoring.
SKIP: {
    eval { require Hyperman::Install::Files; 1 }
        or skip 'Install::Files not built (run make first)', 2;
    no warnings 'once';
    my $inc = $Hyperman::Install::Files::inc;
    ok(defined $inc && length $inc, 'Install::Files records an include path');
    like($inc, qr/-I/, 'include path carries -I dirs for dependents');
}

done_testing;
