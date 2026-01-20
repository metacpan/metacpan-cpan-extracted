#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Linux::Landlock::Direct qw(:functions :constants set_no_new_privs);

my $MIN_ABI_VERSION = 6;
CORE::say ll_get_abi_version();
if (ll_get_abi_version() < $MIN_ABI_VERSION) {
    ok(scalar ll_all_scoped_supported() == 0, "no support");
} else {
    ok(ll_all_scoped_supported() >= Math::BigInt->bone()->blsft(2) - 1, "plausible list");
    my $ruleset_fd = ll_create_ruleset(undef, undef, $LANDLOCK_SCOPED{ABSTRACT_UNIX_SOCKET} | $LANDLOCK_SCOPED{SIGNAL});
    CORE::say ll_get_abi_version();
  SKIP: {
    skip "Tests not possible on this kernel", if ll_get_abi_version() < $MIN_ABI_VERSION;
        ok($ruleset_fd > 0, "ruleset created");
        my $ppid = getppid;
        ok(kill(0, $ppid),                "can signal parent ($ppid)");
        ok(set_no_new_privs(),            "no new privs set");
        ok(ll_restrict_self($ruleset_fd), "successfully restricted");
        ok(!kill(0, $ppid),               "cannot signal parent ($ppid)");
        my $pid = fork;
        if (!defined $pid) {
            die "fork failed: $!";
        } elsif ($pid == 0) {
            exit 0;
        } else {
            ok(kill(0, $pid), "can signal child ($pid)");
            waitpid($pid, 0);
        }
    }
}

done_testing();
