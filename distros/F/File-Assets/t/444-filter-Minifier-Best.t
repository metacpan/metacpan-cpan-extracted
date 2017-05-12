#!perl -w
BEGIN {
    use Test::More;
#    plan skip_all => 'Minifier::XS is too buggy right now';
    plan skip_all => 'install JavaScript::Minifier::* and CSS:Minifier::* to enable this test' and exit unless 
        (eval "require JavaScript::Minifier::XS" &&
        eval "require CSS::Minifier::XS") ||
        (eval "require JavaScript::Minifier" &&
        eval "require CSS::Minifier")
    ;
}

use strict;

use Test::More qw/no_plan/;
use t::Test;

{
    my $assets = t::Test->assets(output_path => '%n%-l.%e', qw/minify best/);
    my $scratch = t::Test->scratch;
    my $filter;

    $assets->include("css/apple.css");
    $assets->include("css/banana.css");
    $assets->include("css/cherry.css");
    $assets->include("js/apple.js");
    $assets->include("js/cherry.js");

    ok($scratch->exists("static/css/cherry.css"));
    ok(-s $scratch->file("static/css/cherry.css"));

    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));

    ok($scratch->exists("static/assets.css"));
    ok(-s $scratch->file("static/assets.css"));
    is($scratch->read("static/assets.css"), 'div.cherry{font-weight:bold;font-weight:100;border:1px solid #aaaaaa}div.cherry em{color:red}');

    ok($scratch->exists("static/assets.js"));
    ok(-s $scratch->file("static/assets.js"));
    is($scratch->read("static/assets.js"), '(function(){alert("Nothing happens.");var cherry=1+2;return function(alpha,beta,delta){return alpha+beta+delta;}}());');
}
