#!perl
use strict;
use warnings;
use Test::More;
use Hyperman;

# The public C ABI (include/hyperman/hm_abi.h): the versioned function-pointer
# table reached through Hyperman::_abi_ptr, and the EU::Depends provider
# config that lets a consumer (e.g. DBIx::Loop) find the header without
# copying it.

# _abi_ptr returns the address of the process-wide table as a positive IV.
my $ptr = Hyperman::_abi_ptr();
ok(defined $ptr && $ptr > 0, "_abi_ptr returns a table address ($ptr)");

# _abi_selftest resolves the table in C and drives every entry: future
# lifecycle (done/fail/on_ready, double-settle no-op), a C io watcher on a
# pipe, a cancelled timer, and a live timer, pumped with run_until.
is(Hyperman::_abi_selftest(), 1,
   '_abi_selftest: loop, watchers, timers and futures through the ABI table');

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
