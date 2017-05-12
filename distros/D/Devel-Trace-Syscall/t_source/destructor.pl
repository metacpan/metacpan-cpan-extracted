#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

{
    package Guard;

    sub DESTROY {
        open my $fh, '<', '/dev/null';
    }
}

my $g = bless {}, 'Guard';

__DATA__
open("/dev/null", 0x0, 0666) = * at destructor.pl line 11.
        Guard::DESTROY(*) called at destructor.pl line 0
        eval {...} called at destructor.pl line 0
