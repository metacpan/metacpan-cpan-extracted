#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Test::Warnings;

use HTTP::Headers::ActionPack;
use HTTP::Headers::ActionPack::AuthenticationInfo;

{
    my $auth = HTTP::Headers::ActionPack::AuthenticationInfo->new(
        foo => 42,
        bar => undef,
    );

    isa_ok(
        $auth, 'HTTP::Headers::ActionPack::AuthenticationInfo',
        'object from constructor'
    );

    is( $auth->as_string, q{foo="42", bar=""}, 'auth header as string' );
}

{
    my $auth = HTTP::Headers::ActionPack->new->create_header(
        'Authentication-Info',
        q{foo="42", bar=},
    );

    isa_ok(
        $auth, 'HTTP::Headers::ActionPack::AuthenticationInfo',
        'object from $pack->create_header'
    );

    is( $auth->as_string, q{foo="42", bar=""}, 'auth header as string' );
}

done_testing();
