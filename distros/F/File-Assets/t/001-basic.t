#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
my $assets = t::Test->assets;
my $scratch = t::Test->scratch;
my $html;

ok(-e $scratch->base->file("static/css/apple.css"));
ok(-e $scratch->base->file("static/css/banana.css"));
ok(-e $scratch->base->file("static/js/apple.js"));

ok($assets->include("css/apple.css"));
ok($assets->include("js/apple.js"));

compare($assets->export, qw(
    http://example.com/static/css/apple.css
    http://example.com/static/js/apple.js
));

compare($assets->export('css'), qw(
    http://example.com/static/css/apple.css
));

compare($assets->export('js'), qw(
    http://example.com/static/js/apple.js
));

ok($assets->include("css/banana.css"));

compare($assets->export, qw(
    http://example.com/static/css/apple.css
    http://example.com/static/css/banana.css
    http://example.com/static/js/apple.js
));

use Test::Memory::Cycle;
memory_cycle_ok($assets);
