#!/usr/bin/perl -w
## basic.t -- initial TDD work for HTML::Tag

use strict;
use warnings;

use Test::More qw(no_plan);


use lib '../lib';
use HTML::TagCloud::Simple;


# scope hacking
my %in;
my $out;

%in = (
    foo => {
        count => 42,
        link_rel => '<base>?value=<value>',
    },
    bar => {
        count => 13,
        link_abs => 'http://foo.com/foo.php?value=bar',
    },
    baz => {
        count => 5,
        link_rel => '<base>?value=<value>',
    },    
);

$out = HTML::TagCloud::Simple::build_cloud(\%in, 'http://foo.com/foo.php', 50, 50, 0);
is (defined $out, 1, "some content was returned -- rel and abs links -- 1");
is ($out, q{<div id="tag_cloud_1" style="display: inline; border-style: solid; border-width: 1px; border-color: #000000; position: absolute; height: 50; width: 50;"> <a href=http://foo.com/foo.php?value=bar title=13><span style='font-face: monospace; font-size: 85%'>bar</span></a> <a href="http://foo.com/foo.php?value=5" title="5"><span style="font-face: monospace; font-size: 70%;">baz</span></a> <a href="http://foo.com/foo.php?value=42" title="42"><span style="font-face: monospace; font-size: 130%;">foo</span></a></div>}, "sane content -- 1");

%in = (
    foo => {
        count => 42,
        link_rel => '<base>?value=<value>',
    },
    bar => {
        count => 13,
        link_abs => 'http://foo.com/foo.php?value=bar',
    },
    baz => {
        count => 5,
        link_rel => '<base>?value=<value>',
    },    
);

$out = HTML::TagCloud::Simple::build_cloud(\%in, 'http://foo.com/foo.php', 50, 50, 0, 10);
is (defined $out, 1, "some content was returned -- skipping a tag less than \$min -- 2");
is ($out, q{<div id="tag_cloud_1" style="display: inline; border-style: solid; border-width: 1px; border-color: #000000; position: absolute; height: 50; width: 50;"> <a href=http://foo.com/foo.php?value=bar title=13><span style='font-face: monospace; font-size: 85%'>bar</span></a> <a href="http://foo.com/foo.php?value=42" title="42"><span style="font-face: monospace; font-size: 130%;">foo</span></a></div>}, "sane content -- 2");

%in = (
    one => {
        count => 1,
        link_rel => '<base>?value=<value>',
    },
    two => {
        count => 22,
        link_abs => 'http://foo.com/foo.php?value=bar',
    },
    three => {
        count => 44,
        link_rel => '<base>?value=<value>',
    },
    four => {
        count => 64,
        link_rel => '<base>?value=<value>',
    },
    five => {
        count => 84,
        link_rel => '<base>?value=<value>',
    },
    
);

$out = HTML::TagCloud::Simple::build_cloud(\%in, 'http://foo.com/foo.php', 100, 100, 0);

is (defined $out, 1, "some content was returned -- exercising all font-size specifications -- 3");
is ($out, q{<div id="tag_cloud_1" style="display: inline; border-style: solid; border-width: 1px; border-color: #000000; position: absolute; height: 100; width: 100;"> <a href="http://foo.com/foo.php?value=84" title="84"><span style="font-face: monospace; font-size: 130%;">five</span></a> <a href="http://foo.com/foo.php?value=64" title="64"><span style="font-face: monospace; font-size: 115%;">four</span></a> <a href="http://foo.com/foo.php?value=1" title="1"><span style="font-face: monospace; font-size: 70%;">one</span></a> <a href="http://foo.com/foo.php?value=44" title="44"><span style="font-face: monospace; font-size: 100%;">three</span></a> <a href=http://foo.com/foo.php?value=bar title=22><span style='font-face: monospace; font-size: 85%'>two</span></a></div>}, "sane content -- 3");

## build a 100 element hash
%in = ( '_internal' => { 'base' => 'http://bar.com/bar.php', count => 0 } );
for (my $i = 0; $i < 100; $i++) {
    my $key = $i;
    $in{$key}{count}    = $key;
    $in{$key}{link_rel} = '<base>?value=<value>';
}

$out = HTML::TagCloud::Simple::build_cloud(\%in, 'http://foo.com/foo.php', 200, 200, 0);
is (defined $out, 1, "some content was returned -- 100 element hash -- 4");

exit;
