#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

get '/render' => sub {
    my $req = shift;
    +{
        -view => 'TT',
        -template => $req->param(tpl => '.+'),
        foo => 42,
    };
};

warnings_like {
    my ($status, $head, $content) = neaf->run_test( '/render?tpl=foo.html' );
    is $status, 500, "Template not found";
} [qr/req_id=/], "Warning logged";

warnings_like {
    neaf->load_resources(\*DATA);
} [{ carped => qr/Xslate/ }], "Xslate hasn't been loaded = warn";

my ($status, $head, $content) = neaf->run_test( '/render?tpl=foo.html' );
is $status, 200, "Template found now";
is $content, 'FOO=42', "Rendered as expected";

($status, $head, $content) = neaf->run_test( '/favicon.ico' );
is $status, 200, "Static found";
is $head->header("content-type"), 'image/png', "Content-type survived";

($status, $head, $content) = neaf->run_test( '/render?tpl=base64.html' );
is $status, 200, "Status ok";
is $content, "<b>so?</b>", "Template decoded (base64)";

# NOTE PGI+c28/PC9iPg== is base64 encoding of "<b>so?</b>".
#    ">" and "?" are 62nd and 63rd symbols in ascii, respectively
#    They are put at the end of a triad to guarantee their last 6 bits
#    get encoded in one "digit".
#    Thus, correct decoding of base64 is proven.

# Same, but with URL-friendly variant
($status, $head, $content) = neaf->run_test( '/render?tpl=base64url.html' );
is $status, 200, "Status ok";
is $content, "<b>so?</b>", "Template decoded (base64url)";

done_testing;

__DATA__

garbage

@@ foo.html view=TT
FOO=[% foo %]

@@ bar.html view=TT
BAR=[% bar %]

@@ baz.html view=Xslate
<: xslate_unsupported :>

@@ base64.html format=base64 view=TT
PGI+c28/PC9iPg==

@@ base64url.html format=base64 view=TT
PGI-c28_PC9iPg

@@ /favicon.ico format=base64 type=png

iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAABGdBTUEAALGPC/xhBQAAAAFzUkdC
AK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAQhQTFRF
