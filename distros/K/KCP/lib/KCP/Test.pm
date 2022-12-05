#
# Copyright (c) homqyy
#
package KCP::Test;

use 5.026003;
use strict;
use warnings;
use Test::More;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    invalid_test
);

sub invalid_test
{
    local $@;

    my ($title, $kcp, $sub, @args) = @_;

    eval {
        local $SIG{__WARN__} = sub {};

        $kcp->$sub(@args);
    };

    ok($@, $title);
}

1;