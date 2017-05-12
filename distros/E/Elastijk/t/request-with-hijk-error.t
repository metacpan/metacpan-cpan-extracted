#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Hijk;

{
    no warnings 'redefine';
    sub Hijk::request {
        return { error => Hijk::Error::CANNOT_RESOLVE }
    };
}

use Elastijk;

subtest "Elastijk::request_raw, with a Hijk error." => sub {

    my ($status, $res_body) = Elastijk::request_raw({ body => q<{"query":{"match_all":{}}}> });

    ok defined($status);
    ok defined($res_body);

    ok(substr($status,0,1) ne "2");

    my $res = $Elastijk::JSON->decode($res_body);
    ok( exists $res->{error} );
    ok( exists $res->{hijk_error} );

    is( $res->{hijk_error}, Hijk::Error::CANNOT_RESOLVE );
};

subtest "oo request, with a Hijk error." => sub {
    my $es = Elastijk->new();

    my ($status, $res) = $es->request( body => {query=>{match_all=>{}}} );

    ok defined($status);
    ok defined($res);

    ok(substr($status,0,1) ne "2");

    ok( exists $res->{error} );
    ok( exists $res->{hijk_error} );

    is( $res->{hijk_error}, Hijk::Error::CANNOT_RESOLVE );
};

done_testing;
