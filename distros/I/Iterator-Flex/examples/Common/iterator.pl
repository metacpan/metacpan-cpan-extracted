#! /usr/bin/perl
use strict;
use warnings;
use v5.10.0;

use Iterator::Flex::Common ':all';

my $seq = 0;
my $iter = iterator { return $seq < 100 ? ++$seq : undef } ;
while ( defined ( my $r = $iter->() ) ) {
    #...
}
1;

