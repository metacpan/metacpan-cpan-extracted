#!perl -w
use strict;

use List::Util qw(first);;

print first{ $_ > 1 } 1 .. 100;
print "\n";
