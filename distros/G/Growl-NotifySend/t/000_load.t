#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Growl::NotifySend';
}

diag "Testing Growl::NotifySend/$Growl::NotifySend::VERSION";
