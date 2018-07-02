#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

get '/foo' => sub { +{ foo => 42 } }, -view => 'TT', -template => 'x.html';

warnings_like {
    neaf->load_resources(\*DATA);
} [ { carped => qr{DEPRECATE.*resource format.*@@} } ], "Loaded with warning";

my ($status, undef, $content) = neaf->run_test( '/foo' );
is $status, 200, "Request served";
is $content, "foo=42", "Template worked";

done_testing;

__DATA__

@@ [TT] x.html

foo=[% foo %]
