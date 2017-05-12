package Heap::Simple::Less;
$VERSION = "0.02";
use strict;

sub _ORDER_PREPARE {
    return "my \$order = \$heap->[0]{order};";
}

sub _SMALLER {
    return "\$order->($_[1], $_[2])";
}

sub order {
    return shift->[0]{order};
}

1;
