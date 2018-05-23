use strict;
use warnings;
use Test::More 0.96;
use File::pushd;

eval {
    my $dir = tempd;
    die("error\n");
};

my $err = $@;
is( $err, "error\n", "destroy did not clobber \$@\n" );

done_testing;
#
# This file is part of File-pushd
#
# This software is Copyright (c) 2018 by David A Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
