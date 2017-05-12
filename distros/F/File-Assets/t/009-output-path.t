#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
use Path::Class;

my $assets = t::Test->assets;

sub output_asset_path {
    return output_asset(@_)->path;
}

sub output_asset {
    return File::Assets::Asset->new(path => output_path(@_),
        base => $assets->rsc, type => "text/css");
}

sub output_path {
    return File::Assets::Util->build_output_path(shift, { name => "assets",
        kind => "css-screen",
        type => "text/css",
        extension => "css",
    @_ });
}

is(output_asset_path("xyzzy/"), "/static/xyzzy/assets.css");
is(output_asset_path(dir "xyzzy"), "/static/xyzzy/assets.css");
is(output_asset_path("xyzzy"), "/static/xyzzy.css");
is(output_asset_path(\"xyzzy"), "/static/xyzzy");
is(output_asset_path(\"/xyzzy"), "/xyzzy");
is(output_asset_path("/xyzzy"), "/xyzzy.css");
is(output_asset_path("/%n/%e/xyzzy.%e"), "/assets/css/xyzzy.css");
is(output_asset_path("built/1.2.4.%e"), "/static/built/1.2.4.css");
is(output_asset_path("built/%n.1.2.4.%e"), "/static/built/assets.1.2.4.css");
