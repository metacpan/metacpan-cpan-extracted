#!/usr/bin/env perl

use strict;
use warnings;

sub foo {
    open my $fh, '<', '/dev/null';
    (undef) = <$fh>;
    close $fh;
}

foo();

__DATA__
# args: read
# extra: 1

read(*, *, *) = * at read.pl line 8.
    main::foo() called at read.pl line 12
