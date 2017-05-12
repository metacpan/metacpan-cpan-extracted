#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'HTML::Lint::Pluggable';
}

diag "Testing HTML::Lint::Pluggable/$HTML::Lint::Pluggable::VERSION";
