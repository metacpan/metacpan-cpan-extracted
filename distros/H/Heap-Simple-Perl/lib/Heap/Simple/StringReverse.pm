package Heap::Simple::StringReverse;
$VERSION = "0.03";
use strict;

sub _SMALLER {
    return "$_[1] gt $_[2]";
}

sub _INF {
    return "";
}

sub order {
    return "gt";
}

1;
