#!/usr/bin/perl

use 5.010;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

BEGIN {
    use_ok ('Math::Sequence::DeBruijn') or
        BAIL_OUT ("Loading of 'Math::Sequence::DeBruijn' failed");
}

ok defined $Math::Sequence::DeBruijn::VERSION, "VERSION is set";

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
