#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my @trace;
neaf helper => log_message => sub { push @trace, $_[2] };

neaf 404 => sub {
    die "Dead handler";
};
neaf 500 => sub {
    my ($req, %opt) = @_;

    return { -content => ''.$opt{error}->reason };
};

get '/foo' => sub {
    die bless {}, 'Foo';
};

subtest 'blessed die & bad handler' => sub {
    @trace = ();
    my ($status, $head, $content) =  neaf->run_test( '/foo' );
    is $status, 500, 'died = internal server error';
    like $content, qr(^Foo=HASH), 'content reflects actual exception';
    is scalar @trace, 0, 'nothing to log yet';
};

subtest 'dying 404' => sub {
    @trace = ();
    my ($status, $head, $content) =  neaf->run_test( '/bar' );
    is scalar @trace, 1, 'exception logged';
    like $trace[0], qr(error_template.*404.*Dead handler), 'contains failure reason';
    is $status, 404, 'error preserved';
    like $content, qr(<title>Error 404</title>), 'default HTML stub returned';
};

done_testing;
