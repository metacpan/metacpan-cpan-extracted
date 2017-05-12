#!perl -w
BEGIN {
    use Test::More;
    plan skip_all => 'install ./yuicompressor.jar to enable this test' and exit unless -e "./yuicompressor.jar"
}

use strict;

use Test::More qw/no_plan/;
use t::Test;

my $scratch = t::Test->scratch;
my $assets = t::Test->assets(
    output_path => [
        [ ":yuicompressor" => "YUI.%e" ],
    ],
);
my $filter;

$assets->include("css/apple.css");
$assets->include("css/banana.css");
$assets->include("js/apple.js");

#diag($scratch->read("YUI.css"));
#<link rel="stylesheet" type="text/css" href="http://example.com/static/0721489ea0ebb3a72f863ebb315cd6ad.css" />

ok($filter = $assets->filter(css => "yuicompressor:./yuicompressor.jar"));
is($filter->cfg->{jar}, "./yuicompressor.jar");
compare($assets->export, qw(
    http://example.com/static/YUI.css
    http://example.com/static/js/apple.js
));
ok($scratch->exists("static/YUI.css"));
is(-s $scratch->file("static/YUI.css"), 0);

ok($assets->filter(js => "yuicompressor" => { jar => "./yuicompressor.jar" }));
compare($assets->export, qw(
    http://example.com/static/YUI.css
    http://example.com/static/YUI.js
));
ok($scratch->exists("static/YUI.js"));
is(-s $scratch->file("static/YUI.js"), 0);

$assets->filter_clear;

$assets->{output_path_scheme} = [
    [ ":yuicompressor" => "xyzzy/YUI.%e" ],
];

ok($assets->filter(js => "yuicompressor" => { jar => "./yuicompressor.jar" }));
compare($assets->export, qw(
    http://example.com/static/css/apple.css
    http://example.com/static/css/banana.css
    http://example.com/static/xyzzy/YUI.js
));
ok($scratch->exists("static/xyzzy/YUI.js"));
is(-s $scratch->file("static/xyzzy/YUI.js"), 0);

__END__

my $assets = t::Test->assets(
    filters => [
        [ "css" => File::Assets::Filter::Concat->new, ],
    ],
    output_path => [
        [ "css" => "$digest" ],
    ],
);
my $scratch = t::Test->scratch;

$assets->include("css/apple.css");
$assets->include("css/banana.css");
$assets->include("js/apple.js");

is($assets->export, <<_END_);
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/$digest.css" />
_END_

ok($scratch->exists("static/$digest.css"));
ok(-s $scratch->file("static/$digest.css"));
is($scratch->read("static/$digest.css"), <<_END_);
/* Test file: static/css/apple.css */

/* Test file: static/css/banana.css */
_END_

#ok($assets->filter([ "concat" => type => ".css", output => '%D.%e', ]));
#is($assets->export, <<_END_);
#<link rel="stylesheet" type="text/css" href="http://example.com/static/$digest.css" />
#<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
#_END_

#ok($scratch->exists("static/$digest.css"));
#ok(-s $scratch->file("static/$digest.css"));
