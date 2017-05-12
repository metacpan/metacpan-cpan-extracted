#!perl -w

use strict;
BEGIN{ $SIG{__WARN__} = sub{ 42 } }
use Devel::Optrace -all;

print 10, (warn 'warning'), 20, "\n";
