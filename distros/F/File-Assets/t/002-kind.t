#!perl -w

use strict;

use Test::More qw/no_plan/;

use t::Test;
my $assets = t::Test->assets;

my ($asset, $kind);

$asset = $assets->include("apple.css");
$kind = File::Assets->kind($asset);
ok($kind);
is($kind->kind, "css");

is(File::Assets->kind($assets->include("apple.js"))->kind, "js");

$asset->attributes->{media} = "print";
is(File::Assets->kind($asset)->kind, "css-print");

ok(File::Assets::Kind->new("css-screen")->is_better_than(File::Assets::Kind->new("css")));
ok(!File::Assets::Kind->new("css")->is_better_than(File::Assets::Kind->new("css-screen")));
ok(!File::Assets::Kind->new("css-print")->is_better_than(File::Assets::Kind->new("css-screen")));
ok(File::Assets::Kind->new("css-screen-tv")->is_better_than(File::Assets::Kind->new("css-screen")));

