#!perl -w

use strict;

use Test::More qw/no_plan/;

use t::Test;
my $assets = t::Test->assets;

$assets->include("apple.css", { qw/media screen/ });
compare($assets->export, qw(
    css-screen;http://example.com/static/apple.css
));

$assets->include("apple.js");
$assets->include("banana.css", { qw/media print/ });
compare($assets->export, qw(
    css-print;http://example.com/static/banana.css
    css-screen;http://example.com/static/apple.css
    http://example.com/static/apple.js
));

