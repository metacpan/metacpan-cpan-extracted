#!perl -T

use warnings;
use strict;
use Test::More tests => 2;

my (@before, @after);

sub sublist {
    sort grep {*{$main::{$_}}{CODE}} keys %main::
}

BEGIN {@before = sublist}

use List::Gen ();

@after = sublist;

ok grep($_ eq 'sublist', @before), 'sublist sanity check';
is_deeply \@after, \@before, 'empty import list';
