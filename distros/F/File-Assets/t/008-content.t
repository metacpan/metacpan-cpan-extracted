#!perl -w

use strict;

use Test::Memory::Cycle;
use Test::More qw/no_plan/;
use t::Test;
my $scratch = t::Test->scratch;

ok(-e $scratch->base->file("static/css/apple.css"));
ok(-e $scratch->base->file("static/css/banana.css"));
ok(-e $scratch->base->file("static/js/apple.js"));

sub assets {
    my $assets = t::Test->assets(@_);

    ok($assets->include("css/apple.css"));
    ok($assets->include("js/apple.js"));
    ok($assets->include_content(<<_END_, "css"));
div {
    background: red;
}
_END_

    return $assets;
}

{
    my $assets = assets;

    compare($assets->export, qw(
            http://example.com/static/css/apple.css
        ), [ css => <<_END_ ],
div {
    background: red;
}
_END_
            "http://example.com/static/js/apple.js"
    );

    compare($assets->export('css'), qw(
            http://example.com/static/css/apple.css
        ), [ css => <<_END_ ],
div {
    background: red;
}
_END_
    );


    compare($assets->export('js'), qw(
            http://example.com/static/js/apple.js
    ));

    ok($assets->include("css/banana.css"));

    compare($assets->export, qw(
            http://example.com/static/css/apple.css
        ), [ css => <<_END_ ],
div {
    background: red;
}
_END_
        qw(
            http://example.com/static/css/banana.css
            http://example.com/static/js/apple.js
    ));

    memory_cycle_ok($assets);
}

{
    my $assets = assets(output_path => [
        [ "*" => '%d.%e' ],
            
    ], filter => [
        [ qw/css concat/, { skip_inline => 0, content_digest => 1 } ],
    ]);
    my $digest = "4622fcfb3d29438ce9298d288fdcc57e";
    ok($assets->include("css/banana.css"));

    compare($assets->export,
        "http://example.com/static/$digest.css",
        "http://example.com/static/js/apple.js",
    );

    ok($scratch->exists("static/$digest.css"));
    ok(-s $scratch->file("static/$digest.css"));
    is($scratch->read("static/$digest.css"), <<_END_);
/* Test file: static/css/apple.css */

div {
    background: red;
}
/* Test file: static/css/banana.css */
_END_

    $scratch->delete("static/$digest.css");
}

SKIP: {
    skip 'install ./yuicompressor.jar to enable this test' unless -e "./yuicompressor.jar";
    my $assets = assets(output_path => [
        [ "*" => '%d.%e' ],
            
    ], filter => [
        [ qw(css yuicompressor:./yuicompressor.jar), { skip_inline => 0, content_digest => 1 } ],
    ]);
    my $digest = "4622fcfb3d29438ce9298d288fdcc57e";
    ok($assets->include("css/banana.css"));

    compare($assets->export,
        "http://example.com/static/$digest.css",
        "http://example.com/static/js/apple.js",
    );
    ok($scratch->exists("static/$digest.css"));
    ok(-s $scratch->file("static/$digest.css"));
    is($scratch->read("static/$digest.css"), 'div{background:red;}');
}

{
    my $assets = assets(output_path => [
        [ "*" => '%d.%e' ],
            
    ], filter => [
        [ qw/css concat/, { content_digest => 1 } ],
    ]);
    my $digest = "408d257d77bf611e910a689912e0befa";

    my $asset = $assets->include(\<<_END_, undef, "css");
span {
    border: 1px solid black;
}
_END_
    $asset->inline(0);
    $assets->include_content(<<_END_, "css", { inline => 0 });
span {
    padding: 1em;
}
_END_
    $assets->include_content(<<_END_, { type => "css", inline => 1 });
span {
    margin: 1em;
}
_END_

    compare($assets->export,
        "http://example.com/static/$digest.css",
        [ css => <<_END_ ],
div {
    background: red;
}
_END_
        [ css => <<_END_ ],
span {
    margin: 1em;
}
_END_
        "http://example.com/static/js/apple.js",
    );

    compare($assets->export,
        "http://example.com/static/$digest.css",
        [ css => <<_END_ ],
div {
    background: red;
}
_END_
        [ css => <<_END_ ],
span {
    margin: 1em;
}
_END_
        "http://example.com/static/js/apple.js",
    );

    ok($scratch->exists("static/$digest.css"));
    ok(-s $scratch->file("static/$digest.css"));
    local $/ = undef;
    is($scratch->read("static/$digest.css"), <<_END_);
/* Test file: static/css/apple.css */

span {
    border: 1px solid black;
}
span {
    padding: 1em;
}
_END_

    $scratch->delete("static/$digest.css");
}

