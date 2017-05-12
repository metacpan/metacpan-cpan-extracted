#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
my $assets = t::Test->assets;
my $scratch = t::Test->scratch;

$assets->include("css/apple.css");
compare($assets->export, qw(
    http://example.com/static/css/apple.css
));

$assets->include("css/banana.css", -10);
compare($assets->export, qw(
    http://example.com/static/css/banana.css
    http://example.com/static/css/apple.css
));

$assets->include("css/cherry.css", 0);
compare($assets->export, qw(
    http://example.com/static/css/banana.css
    http://example.com/static/css/apple.css
    http://example.com/static/css/cherry.css
));

$assets->include("js/cherry.js", -5);
compare($assets->export, qw(
    http://example.com/static/css/banana.css
    http://example.com/static/js/cherry.js
    http://example.com/static/css/apple.css
    http://example.com/static/css/cherry.css
));

$assets->include("js/apple.js", -100);
compare($assets->export, qw(
    http://example.com/static/js/apple.js
    http://example.com/static/css/banana.css
    http://example.com/static/js/cherry.js
    http://example.com/static/css/apple.css
    http://example.com/static/css/cherry.css
));

compare($assets->export('css'), qw(
    http://example.com/static/css/banana.css
    http://example.com/static/css/apple.css
    http://example.com/static/css/cherry.css
));

compare($assets->export('js'), qw(
    http://example.com/static/js/apple.js
    http://example.com/static/js/cherry.js
));
