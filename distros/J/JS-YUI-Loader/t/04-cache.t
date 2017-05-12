use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;
use Directory::Scratch;
my $scratch = Directory::Scratch->new;
my $base = $scratch->base;
sub file { return $base->file(@_) }

use JS::YUI::Loader::Catalog;
use JS::YUI::Loader::Source::YUIHost;
use JS::YUI::Loader::Source::YUIHost;
use JS::YUI::Loader::Cache::URI;

my $catalog = JS::YUI::Loader::Catalog->new;
my $source = JS::YUI::Loader::Source::YUIHost->new(catalog => $catalog);
my $cache = JS::YUI::Loader::Cache::URI->new(source => $source, dir => $base, uri => "http://example.com/t");
ok($cache);

SKIP: {
    $ENV{TEST_YUI_HOST} or skip "Not testing going out to the yui host";
    is($cache->uri("yuitest"), "http://example.com/t/yuitest.js");
    is($cache->uri("yuitest-min"), "http://example.com/t/yuitest-min.js");
    is($cache->file("yuitest"), file "yuitest.js");
}
