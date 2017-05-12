#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
my $assets = t::Test->assets;
my $scratch = t::Test->scratch;

my $asset;
my @file;
my $assets1 = $asset = $assets->include("/css/apple.css");
ok($asset);
is($asset->uri, "http://example.com/css/apple.css");
is($asset->path, "/css/apple.css");
is($asset->file, $scratch->base->file("/css/apple.css"));

my $assets2 = $asset = $assets->include("css/apple.css");
ok($asset);
is($asset->uri, "http://example.com/static/css/apple.css");
is($asset->path, "/static/css/apple.css");
is($asset->file, $scratch->base->file("/static/css/apple.css"));
isnt($assets1, $assets2);

my $assets3 = $asset = $assets->include("/static/css/apple.css");
is($assets2, $assets3);
