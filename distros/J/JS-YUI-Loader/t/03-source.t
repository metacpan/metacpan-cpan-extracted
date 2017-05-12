use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;

use JS::YUI::Loader::Catalog;
use JS::YUI::Loader::Source::YUIHost;
use JS::YUI::Loader::Source::YUIDir;

my $catalog = JS::YUI::Loader::Catalog->new;
my $source_yui_host = JS::YUI::Loader::Source::YUIHost->new(catalog => $catalog);
my $source_yui_dir = JS::YUI::Loader::Source::YUIDir->new(catalog => $catalog, base => "yui/build");
ok($source_yui_host);
ok($source_yui_dir);

is($source_yui_host->uri("yuitest"), "http://yui.yahooapis.com/2.5.1/build/yuitest/yuitest.js");
is($source_yui_host->uri([qw/yuitest min/]), "http://yui.yahooapis.com/2.5.1/build/yuitest/yuitest-min.js");
is($source_yui_host->uri("imagecropper"), "http://yui.yahooapis.com/2.5.1/build/imagecropper/imagecropper-beta.js");
is($source_yui_host->uri([qw/imagecropper min/]), "http://yui.yahooapis.com/2.5.1/build/imagecropper/imagecropper-beta-min.js");

is($source_yui_dir->file("yuitest"), "yui/build/yuitest/yuitest.js");
is($source_yui_dir->file([qw/yuitest min/]), "yui/build/yuitest/yuitest-min.js");
is($source_yui_dir->file("imagecropper"), "yui/build/imagecropper/imagecropper-beta.js");
is($source_yui_dir->file("imagecropper-min"), "yui/build/imagecropper/imagecropper-beta-min.js");
