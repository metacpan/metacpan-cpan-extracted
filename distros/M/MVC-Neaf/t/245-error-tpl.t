#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

neaf 403 => sub {
    my $req = shift;
    return {
        -headers  => [ x_foo_bar => 42 ],
        -view     => 'TT',
        -template => \'<h1>Access to [% path %] forbidden</h1>',
         path     => $req->path,
    };
};

get '/nope' => sub {
    die 403;
};

my ($status, $head, $content) = neaf->run_test( '/nope' );

is $status, 403, "403 error returned";
is $head->header( "X-Foo-Bar" ), 42, "Custom header processed";
is $head->header( "Content-Type" ), "text/html; charset=utf-8", "Auto content type from TT";
like $content, qr{/nope forbidden}, "Content render as expected";

done_testing;
