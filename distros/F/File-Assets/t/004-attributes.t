#!perl -w

use strict;

use Test::More qw/no_plan/;

use t::Test;
my $assets = t::Test->assets;

$assets->include("apple.css", { qw/media screen lang de/ });
$assets->include("apple.js", { qw/version 2/ });
$assets->include("banana.css");
compare($assets->export,
    "http://example.com/static/banana.css",
    "css-screen;http://example.com/static/apple.css", { qw/lang de/ },
    "http://example.com/static/apple.js", { qw/version 2/ },
);
