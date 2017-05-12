#!/usr/local/bin/perl -w
use strict;
use Test;
use lib 't';
use TestDetails ();

BEGIN {
    plan tests => 1;

    $SIG{__WARN__} = sub {
       ok(0);
       exit;
    }
}

# Check that we compile without warnings.
use HTTP::DAV;
ok(1);
