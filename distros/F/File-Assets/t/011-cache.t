#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
#use JSON::XS;
#my $json = JSON::XS->new->allow_blessed->pretty;
my $scratch = t::Test::Scratch->new;

sub assets {
    my $assets = File::Assets->new(base => [ "http://example.com/", $scratch->base, "/static" ], @_);
    $assets->include("css/apple.css");
    $assets->include("css/banana.css");
    $assets->include("js/apple.js");
    return ($scratch, $assets);
}

my ($cache, $asset, $content, $digest, $size, $mtime);
{
    diag "First assets";
    my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify concat));

    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
    ok($scratch->exists("static/assets.css"));
    cmp_ok(-s $scratch->file("static/assets.css"), '>=' => 64);

    $cache = $assets->cache;
    $asset = $assets->fetch("/static/css/apple.css");
    $content = $asset->_content;
}

{
    diag "Second assets";
    my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify concat));

    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
    ok($scratch->exists("static/assets.css"));
    cmp_ok(-s $scratch->file("static/assets.css"), '>=' => 64);

    is($cache, $assets->cache);
    isnt($asset, $assets->fetch("/static/css/apple.css"));
    is($content, $assets->fetch("/static/css/apple.css")->_content);
    is($asset->digest, $assets->fetch("/static/css/apple.css")->digest);

    $digest = $asset->digest;
}

{
    diag "Third assets, alter 'apple.css'";
    $scratch->write("static/css/apple.css", <<_END_);
/* This is custom.css */
_END_

    my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify concat));

    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
    ok($scratch->exists("static/assets.css"));
    cmp_ok(-s $scratch->file("static/assets.css"), '>=' => 64);

    is($cache, $assets->cache);
    isnt($asset, $assets->fetch("/static/css/apple.css"));
    is($content, $assets->fetch("/static/css/apple.css")->_content);
    isnt($digest, $assets->fetch("/static/css/apple.css")->digest);

    $asset = $assets->fetch("/static/css/apple.css");
    $digest = $asset->digest;
}

{
    diag "Fourth assets";
    my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify concat));

    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
    ok($scratch->exists("static/assets.css"));
    cmp_ok(-s $scratch->file("static/assets.css"), '>=' => 64);

    is($digest, $assets->fetch("/static/css/apple.css")->digest);

    $digest = $asset->digest;
}
