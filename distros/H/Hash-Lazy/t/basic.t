#!/usr/bin/env perl -w
use strict;
use Test::More;

use Hash::Lazy;

my $double = Hash {
    my ($h, $k) = @_;
    return $k * 2;
};

is $$double{4}, 8,  "STORE";

$$double{4} = 12;
is $$double{4}, 12, "STORE + FETCH";

delete $$double{4};
is $$double{4}, 8,  "DELETE + FETCH";

# clear
%$double = ();
is $$double{4}, 8,  "CLEAR + FETCH";

done_testing;
