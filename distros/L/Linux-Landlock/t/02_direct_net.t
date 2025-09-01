#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use IO::File;
use Linux::Landlock::Direct qw(:functions :constants set_no_new_privs);
use IO::Socket::INET;

if (ll_get_abi_version() < 4) {
    ok(scalar ll_all_net_access_supported() == 0, "no support");
} else {
    ok(scalar ll_all_net_access_supported() >= 2, "plausible list");
    my $ruleset_fd = ll_create_ruleset();
    ok($ruleset_fd > 0, "ruleset created");
    is(
        ll_add_net_port_rule($ruleset_fd, $LANDLOCK_ACCESS_NET{BIND_TCP}, 33333),
        $LANDLOCK_ACCESS_NET{BIND_TCP},
        'rule added'
    );
    ok(set_no_new_privs(),            "no new privs set");
    ok(ll_restrict_self($ruleset_fd), "successfully restricted");
    ok(
        defined IO::Socket::INET->new(
            LocalPort => 33333,
            Proto     => 'tcp',
        ),
        "socket created"
    );
    ok(
        !defined IO::Socket::INET->new(
            LocalPort => 33334,
            Proto     => 'tcp',
        ),
        "socket not created: $!"
    );
}
done_testing();
