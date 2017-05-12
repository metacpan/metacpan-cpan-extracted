#!perl -w

use strict;

my $digest = "b11bf9a77b520852e95af3e0b5c1aa95";

use Test::More qw/no_plan/;
use t::Test;
require File::Assets::Filter::Concat;
my $assets = t::Test->assets(
    filters => [
        [ "css" => File::Assets::Filter::Concat->new, ],
    ],
    output_path => [
        [ "css" => "$digest" ],
    ],
);
my $scratch = t::Test->scratch;

$assets->include("css/apple.css");
$assets->include("css/banana.css");
$assets->include("js/apple.js");

compare($assets->export,
    "http://example.com/static/$digest.css",
    "http://example.com/static/js/apple.js",
);

ok($scratch->exists("static/$digest.css"));
ok(-s $scratch->file("static/$digest.css"));
is($scratch->read("static/$digest.css"), <<_END_);
/* Test file: static/css/apple.css */

/* Test file: static/css/banana.css */
_END_

#ok($assets->filter([ "concat" => type => ".css", output => '%D.%e', ]));
#is($assets->export, <<_END_);
#<link rel="stylesheet" type="text/css" href="http://example.com/static/$digest.css" />
#<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
#_END_

#ok($scratch->exists("static/$digest.css"));
#ok(-s $scratch->file("static/$digest.css"));
