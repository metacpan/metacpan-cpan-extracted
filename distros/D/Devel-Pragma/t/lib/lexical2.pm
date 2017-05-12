package lexical2;

use strict;
use warnings;

our $test;

# Devel::Pragma is lexically scoped and shouldn't fix modules "downstream"
# 1 for success if the key has leaked
# 0 for failure if it hasn't
BEGIN { $test = $^H{'Devel::Pragma::Leak'} ? 1 : 0 }

sub test() { $test }

1;
