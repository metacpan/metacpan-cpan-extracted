#!/usr/bin/perl
use 5.016;
use strict;
use warnings;

# My system's iconv does not support HZ :-(

use Encode qw(encode);

while (my $l = <>) {
    my $hz = encode('hz', $l);
    print $hz;
}
