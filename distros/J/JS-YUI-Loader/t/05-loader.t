use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;

use JS::YUI::Loader;
use Directory::Scratch;
my $scratch = Directory::Scratch->new;
my $base = $scratch->base;
sub file { return $base->file(@_) }

my $loader = JS::YUI::Loader->new_from_yui_host(cache => $base);
ok($loader);
SKIP: {
    $ENV{TEST_YUI_HOST} or skip "Not testing going out to the yui host";
    is($loader->file("yuitest"), file "yuitest.js");
}
$loader->filter_min;
SKIP: {
    $ENV{TEST_YUI_HOST} or skip "Not testing going out to the yui host";
    is($loader->file("yuitest"), file "yuitest-min.js");
}
is($loader->item_path("yuitest"), "yuitest/yuitest-min.js");
is($loader->item_file("yuitest"), "yuitest-min.js");

ok(JS::YUI::Loader->new_from_yui_host);
ok(JS::YUI::Loader->new_from_yui_dir(base => "./"));
ok(JS::YUI::Loader->new_from_uri(base => "./"));
ok(JS::YUI::Loader->new_from_dir(base => "./"));

ok(JS::YUI::Loader->new_from_yui_dir(dir => "./"));
ok(JS::YUI::Loader->new_from_dir(dir => "./"));

is(JS::YUI::Loader->new_from_yui_dir(dir => "./yui/\%v/build")->source->base, "yui/2.5.1/build");

