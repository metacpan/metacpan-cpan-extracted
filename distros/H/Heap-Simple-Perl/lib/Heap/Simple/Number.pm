package Heap::Simple::Number;
$VERSION = "0.03";
use strict;

sub _SMALLER {
    return "$_[1] < $_[2]";
}

sub _INF {
    return 9**9**9;
}

sub order {
    return "<";
}

1;
