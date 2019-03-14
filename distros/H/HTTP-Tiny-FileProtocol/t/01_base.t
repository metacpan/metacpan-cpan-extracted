#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Tiny;

use_ok 'HTTP::Tiny::FileProtocol';

diag "Testing HTTP::Tiny::FileProtocol version " . HTTP::Tiny::FileProtocol->VERSION();

my $http = HTTP::Tiny->new;
isa_ok $http, 'HTTP::Tiny';
can_ok $http, 'get';

{
    my $error = '';
    eval {
        $http->get();
    } or $error = $@;

    like $error, qr/Usage: \$http->get\(URL, \[HASHREF\]\)/;
}

{
    my $error = '';
    eval {
        $http->get( 'file:///test.txt', 'anything' );
    } or $error = $@;

    like $error, qr/Usage: \$http->get\(URL, \[HASHREF\]\)/;
}

{
    my $error = '';
    eval {
        $http->get( 'file:///test.txt', [] );
    } or $error = $@;

    like $error, qr/Usage: \$http->get\(URL, \[HASHREF\]\)/;
}

done_testing();
