#!perl -w

use strict;

use Test::More tests => 1;

BEGIN {
    use_ok('Mac::SystemDirectory');
}

diag("Mac::SystemDirectory $Mac::SystemDirectory::VERSION, Perl $], $^X");

