#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf qw(:sugar);

get '/foo' => sub {
    +{
        -view => 'TT',
        -template => 'foo.html',
        foo => 42,
    };
};

warnings_like {
    my ($status, $head, $content) = neaf->run_test( '/foo' );
    is $status, 500, "Template not found";
} [qr/req_id=/], "Warning logged";

neaf->load_resources(\*DATA);

my ($status, $head, $content) = neaf->run_test( '/foo' );
is $status, 200, "Template found now";
is $content, 'FOO=42', "Rendered as expected";

($status, $head, $content) = neaf->run_test( '/favicon.ico' );
is $status, 200, "Static found";
is $head->header("content-type"), 'image/png', "Content-type survived";

done_testing;

__DATA__

garbage

@@ [TT] foo.html
FOO=[% foo %]

@@ [TT] bar.html
BAR=[% bar %]

@@ [Xslate] baz.html
<: xslate_unsupported :>

@@ /favicon.ico format=base64 type=png

iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAABGdBTUEAALGPC/xhBQAAAAFzUkdC
AK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAQhQTFRF
