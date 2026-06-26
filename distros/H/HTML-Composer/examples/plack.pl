#!/usr/bin/env perl

use strict;
use warnings;

use HTML::Composer;
use Plack::Request;
use Plack::Builder;

my $h = HTML::Composer->new();

my $html = [
    head => [
        title => ["My Website!"],
        style =>
          [ $h->unsafe("body { background-color: magenta; color: white; }") ]
    ],
    body => [
        h1 => ["Groovy dude!"],
        p  => ["HTML::Composer rocks!"]
    ]
];

my $app = sub {
    my $req = Plack::Request->new(shift);
    my $res = $req->new_response(200);
    $res->body( $h->html($html) );
    $res->content_type('text/html');
    return $res->finalize;
};

builder {
    $app;
};
