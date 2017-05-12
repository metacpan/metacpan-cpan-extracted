package Heap::Simple::String;
$VERSION = "0.02";
use strict;

sub _SMALLER {
    return "$_[1] lt $_[2]";
}

sub order {
    return "lt";
}

1;
