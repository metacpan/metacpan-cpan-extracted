#!/usr/bin/env perl

=head1 DESCRIPTION

Check that the handler may be the last argument in a route, not the first.

=cut

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get + post '/foo',
    strict => 1,
    param_regex => {
        answer => '\d+',
    },
    sub {
        my $req = shift;
        return {
            -content => $req->param('answer'),
        };
    };

subtest 'Parameter' => sub {
    my ($status, undef, $content) = neaf->run_test( '/foo?answer=42' );
    is $status, 200, 'OK';
    is $content, 42, 'changed value';
};

done_testing;
