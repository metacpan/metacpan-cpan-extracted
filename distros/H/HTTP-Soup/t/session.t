#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;


BEGIN {
    use_ok('HTTP::Soup');
}

sub main {
    test_async();
    test_sync();
    return 0;
}


sub test_async {
    my $session = HTTP::Soup::SessionAsync->new();
    isa_ok($session, 'HTTP::Soup::SessionAsync');
    isa_ok($session, 'HTTP::Soup::Session');
}


sub test_sync {
    my $session = HTTP::Soup::SessionSync->new();
    isa_ok($session, 'HTTP::Soup::SessionSync');
    isa_ok($session, 'HTTP::Soup::Session');
}


exit main() unless caller;
