#
# Copyright (c) homqyy
#
use strict;
use warnings;

use Test::More;
BEGIN { use_ok('KCP'); use_ok('KCP::Test') };

#########################

isa_ok(KCP::new(1), "KCP", "isa object");

ok(
    KCP::new(1) &&
    KCP::new("1"),
    "only a 'conv' param and is numerical"
);

{
    local $@;

    eval {
        local $SIG{__WARN__} = sub {};

        if (KCP::new("ab") ||
            KCP::new("1ab") ||
            KCP::new("ab1"))
        {
            die "error";
        }
    };

    ok($@, "only a 'conv' param and isn't numerical");
}

{
    my $user = "user";
    ok(
        KCP::new(1, $user) &&
        KCP::new(1, \$user), "param: conv, user"
    );
}

done_testing;