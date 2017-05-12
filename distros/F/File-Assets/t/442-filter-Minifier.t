#!perl -w
BEGIN {
    use Test::More;
    plan skip_all => 'install JavaScript::Minifier and CSS:Minifier to enable this test' and exit unless 
        eval "require JavaScript::Minifier" &&
        eval "require CSS::Minifier";
}

use strict;

use Test::More qw/no_plan/;
use t::Test;
{
    my $assets = t::Test->assets(output_path => [ [ qw/* %n%-l.%e/ ] ]);
    my $scratch = t::Test->scratch;
    my $filter;

    $assets->include("css/apple.css");
    $assets->include("css/banana.css");
    $assets->include("css/cherry.css");
    $assets->include("js/apple.js");
    $assets->include("js/cherry.js");

    ok($scratch->exists("static/css/cherry.css"));
    ok(-s $scratch->file("static/css/cherry.css"));

    ok($filter = $assets->filter(css => "minifier"));
    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/js/apple.js
        http://example.com/static/js/cherry.js
    ));
    ok($scratch->exists("static/assets.css"));
    ok(-s $scratch->file("static/assets.css"));
    like($scratch->read("static/assets.css"), qr/div\.cherry/);
    like($scratch->read("static/assets.css"), qr/font-weight/);
    is($scratch->read("static/assets.css"), 'div.cherry{font-weight:bold;font-weight:100;border:1px solid #aaaaaa;}div.cherry em{color:red;}');

    ok($filter = $assets->filter(js => "minifier-javascript"));
    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
    ok($scratch->exists("static/assets.js"));
    ok(-s $scratch->file("static/assets.js"));
    like($scratch->read("static/assets.js"), qr/"Nothing happens\."/);

    $assets->filter_clear($filter);
    $scratch->delete("static/assets.js");

    ok($filter = $assets->filter("minifier"));
    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
    ok($filter = $assets->filter(js => "minifier-javascript"));
    ok($scratch->exists("static/assets.js"));
    ok(-s $scratch->file("static/assets.js"));
    like($scratch->read("static/assets.js"), qr/"Nothing happens\."/);
}
{
    my $assets = t::Test->assets(
        output_path => [ [ qw/* %n%-l.%e/ ] ],
        filter => [
            [ css => 'minifier', ],
            [ js => 'minifier', ],
        ],
    );
    my $scratch = t::Test->scratch;

    $assets->include("css/apple.css");
    $assets->include("css/banana.css");
    $assets->include("css/cherry.css");
    $assets->include("js/apple.js");
    $assets->include("js/cherry.js");

    ok($scratch->exists("static/css/cherry.css"));
#   is(-s $scratch->file("static/css/cherry.css"), 150);
    ok(-s $scratch->file("static/css/cherry.css"));

    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
    ok($scratch->exists("static/assets.css"));
    ok(-s $scratch->file("static/assets.css"));
    like($scratch->read("static/assets.css"), qr/div\.cherry/);
    like($scratch->read("static/assets.css"), qr/font-weight/);
    ok($scratch->exists("static/assets.js"));
    ok(-s $scratch->file("static/assets.js"));
    like($scratch->read("static/assets.js"), qr/"Nothing happens\."/);
}
