package CCstashCallee1;

use strict;
use warnings;

use Devel::Pragma qw(ccstash);

our $CCSTASH;

sub test {
    return $CCSTASH;
}

sub import {
    A();
}

sub A() {
    B();
}

sub B {
    C();
}

sub C {
    D();
}

sub D {
    E();
}

sub E {
    $CCSTASH = ccstash;
}

1;
