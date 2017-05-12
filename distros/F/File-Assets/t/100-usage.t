#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;

sub assets {
    my $scratch = t::Test::Scratch->new;
    my $assets = File::Assets->new(base => [ "http://example.com/", $scratch->base, "/static" ], @_);
    $assets->include("css/apple.css");
    $assets->include("css/banana.css");
    $assets->include("js/apple.js");
    return ($scratch, $assets);
}

{
    my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify concat));

    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
    ok($scratch->exists("static/assets.css"));
    cmp_ok(-s $scratch->file("static/assets.css"), '>=' => 64);

    $scratch->cleanup;
}

SKIP: {
    skip 'install ./yuicompressor.jar to enable this test' unless -e "./yuicompressor.jar";

    {
        my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify ./yuicompressor.jar));

        compare($assets->export, qw(
            http://example.com/static/assets.css
            http://example.com/static/assets.js
        ));
        ok($scratch->exists("static/assets.css"));
        is(-s $scratch->file("static/assets.css"), 0);
    }

    {
        my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify yuicompressor:./yuicompressor.jar));

        compare($assets->export, qw(
            http://example.com/static/assets.css
            http://example.com/static/assets.js
        ));
        ok($scratch->exists("static/assets.css"));
        is(-s $scratch->file("static/assets.css"), 0);
    }
}

{
    my ($scratch, $assets) = assets(qw(output_path %n%-f.%e minify concat));

    compare($assets->export, qw(
        http://example.com/static/assets-b11bf9a77b520852e95af3e0b5c1aa95.css
        http://example.com/static/assets-7442c488c0bf3d37fc6bece0b5b8eea9.js
    ));
}

{
    my ($scratch, $assets) = assets(qw(minify concat));
    $assets->set_output_path("built/");

    compare($assets->export, qw(
        http://example.com/static/built/assets-b11bf9a77b520852e95af3e0b5c1aa95.css
        http://example.com/static/built/assets-7442c488c0bf3d37fc6bece0b5b8eea9.js
    ));
}

{
    my ($scratch, $assets) = assets(qw(minify concat));
    $assets->set_output_path("/built/");

    compare($assets->export, qw(
        http://example.com/built/assets-b11bf9a77b520852e95af3e0b5c1aa95.css
        http://example.com/built/assets-7442c488c0bf3d37fc6bece0b5b8eea9.js
    ));
}

{
    my ($scratch, $assets) = assets(qw(minify concat));
    $assets->set_base_uri("http://example.net");

    compare($assets->export, qw(
        http://example.net/static/assets-b11bf9a77b520852e95af3e0b5c1aa95.css
        http://example.net/static/assets-7442c488c0bf3d37fc6bece0b5b8eea9.js
    ));
}

{
    my $scratch = t::Test::Scratch->new;
    my $assets = File::Assets->new(base => [ "http://example.com/", $scratch->base, "/static" ], qw/minify concat/);
    $assets->set_base_dir($scratch->base->subdir("other"));
    $assets->set_base_path(undef);
    $assets->include("pear.js");

    compare($assets->export, qw(
        http://example.com/assets-efd1b9d6c155e03a834fbdc9b25bec97.js
    ));
}

{
    my $scratch = t::Test::Scratch->new;
    my $assets = File::Assets->new(base => [ "http://example.com/", $scratch->base, "/static" ], qw/minify concat/);
    $assets->set_base_path(undef);
    $assets->include("js/grape.js");
    $assets->include("js/plum.js");

    compare($assets->export, qw(
        http://example.com/assets-fde848242dae1ca8666afec08c099f6a.js
    ));
}

{
    my $scratch = t::Test::Scratch->new;
    my $assets = File::Assets->new(base => [ "http://example.com/", $scratch->base, "/static" ], qw/minify concat/);
    $assets->set_base(qw( uri http://example.org ), dir => $scratch->base, path => undef);
    $assets->include("js/grape.js");
    $assets->include("js/plum.js");

    compare($assets->export, qw(
        http://example.org/assets-fde848242dae1ca8666afec08c099f6a.js
    ));

    $assets->set_base(qw( uri http://example.org ), dir => $scratch->base);
    compare($assets->export, qw(
        http://example.org/assets-fde848242dae1ca8666afec08c099f6a.js
    ));

    $assets->set_base(qw( uri http://example.org ), dir => $scratch->base, path => "");
    compare($assets->export, qw(
        http://example.org/assets-fde848242dae1ca8666afec08c099f6a.js
    ));
}
