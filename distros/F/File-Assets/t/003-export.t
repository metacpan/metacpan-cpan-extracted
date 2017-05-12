#!perl -w

use strict;

use Test::More qw/no_plan/;

use t::Test;
my $assets = t::Test->assets;

$assets->include("apple.css");
compare($assets->export, qw(
    http://example.com/static/apple.css
));

$assets->include("apple.js");
$assets->include("banana.css");
compare($assets->export, qw(
    http://example.com/static/apple.css
    http://example.com/static/banana.css
    http://example.com/static/apple.js
));
