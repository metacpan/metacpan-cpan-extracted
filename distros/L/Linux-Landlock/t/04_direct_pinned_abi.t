#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Linux::Landlock::Direct qw(:functions :constants set_no_new_privs);
use Math::BigInt;

my $PINNED_VERSION     = 1;
my $system_abi_version = ll_get_abi_version();
diag("system ABI version: $system_abi_version");

SKIP: {
    skip "System ABI version $system_abi_version is too low for this test", if $system_abi_version <= $PINNED_VERSION;

    ll_set_max_abi_version($PINNED_VERSION);
    my $abi_version = ll_get_abi_version();
    diag("pinned ABI version: $abi_version");
    is(ll_all_fs_access_supported(), $LANDLOCK_ACCESS_FS{REFER} - 1, "correct list");
    my $ruleset_fd = ll_create_ruleset()
      or die "ruleset creation failed: $!\n";
    opendir my $dir, '/tmp';
    is(
        ll_add_path_beneath_rule(
            $ruleset_fd,
            $LANDLOCK_ACCESS_FS{READ_FILE} | $LANDLOCK_ACCESS_FS{WRITE} | $LANDLOCK_ACCESS_FS{TRUNCATE}, $dir,
        ),
        ($LANDLOCK_ACCESS_FS{READ_FILE} | $LANDLOCK_ACCESS_FS{WRITE}),
        "TRUNCATE is not available in ABI version $abi_version",
    );
}
done_testing();
