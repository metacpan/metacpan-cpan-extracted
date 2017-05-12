#!/usr/bin/perl
# Maintainer: You can auto-translate the examples in
# this file by setting PREPARE=1.  Don't forget to
# hand-check them afterwards to make sure they are
# in fact correct!
use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::EN::Alphabet::Shaw;

my $shavian = Lingua::EN::Alphabet::Shaw->new();

my @html;
my @names;

# Load the data
while (<DATA>) {
   if (/^#\s*(.*)$/) {
       push @names, $1;
       push @html, '';
   } else {
       $html[-1] .= $_;
   }
}

if (defined $ENV{'PREPARE'}) {
    binmode STDOUT, ':utf8';
    open SELF, "<$0";
    while (<SELF>) {
        print $_;
        last if /^__DATA__/;
    }
    close SELF;
    while (@html) {
        my $name = shift @names;
        my $html = shift @html;
        print "# $name\n";
        print $html; 

        # skip the transliterations
        shift @names;
        shift @html;

        print "#\n";
        print $shavian->transliterate_html($html);
    }
} else {
    plan tests => scalar(@html)/2;

    while (@html) {
        my $name = shift @names;
        my $latn = shift @html;
        my $shaw = shift @html;
        shift @names;

        is ($shavian->transliterate_html($latn), $shaw, $name);
    }
}


__DATA__
# Basic test
<html><head><title>This is a test</title></head>
<body>
<h1>This is a test</h1>
<!-- This is a comment. -->
<p>This is a test.  I took some china to
China.  He <em>does</em> like does.  I
<strong>live</strong> near a <strong>live</strong>
wire.</p>
<div><span title="What is this?">This is something
else.</span> This &mdash; contains an entity.
This is a picture. <img
src="http://example.com/demo.png"
alt="This should be translated."/> Here is
<a href="http://example.com">a link</a>.  This is
all the text.</div></body></html>
#
<html><head><title>𐑞𐑦𐑕 𐑦𐑟 𐑩 𐑑𐑧𐑕𐑑</title><meta name="generator" content="Lingua::EN::Alphabet::Shaw" /></head>
<body>
<h1>𐑞𐑦𐑕 𐑦𐑟 𐑩 𐑑𐑧𐑕𐑑</h1>
<!-- This is a comment. -->
<p>𐑞𐑦𐑕 𐑦𐑟 𐑩 𐑑𐑧𐑕𐑑.  𐑲 𐑑𐑫𐑒 𐑕𐑳𐑥 𐑗𐑲𐑯𐑩 𐑑
·𐑗𐑲𐑯𐑩.  𐑣𐑰 <em>𐑛𐑳𐑟</em> 𐑤𐑲𐑒 𐑛𐑴𐑟.  𐑲
<strong>𐑤𐑦𐑝</strong> 𐑯𐑽 𐑩 <strong>𐑤𐑲𐑝</strong>
𐑢𐑲𐑼.</p>
<div><span title="𐑢𐑪𐑑 𐑦𐑟 𐑞𐑦𐑕?">𐑞𐑦𐑕 𐑦𐑟 𐑕𐑳𐑥𐑔𐑦𐑙
𐑧𐑤𐑕.</span> 𐑞𐑦𐑕 &mdash; 𐑒𐑩𐑯𐑑𐑱𐑯𐑟 𐑩𐑯 𐑧𐑯𐑑𐑦𐑑𐑦.
𐑞𐑦𐑕 𐑦𐑟 𐑩 𐑐𐑦𐑒𐑗𐑼. <img alt="𐑞𐑦𐑕 𐑖𐑫𐑛 𐑚𐑰 𐑑𐑮𐑩𐑯𐑕𐑤𐑱𐑑𐑩𐑛." src="http://example.com/demo.png"/> 𐑣𐑽 𐑦𐑟
<a href="http://example.com">𐑩 𐑤𐑦𐑙𐑒</a>.  𐑞𐑦𐑕 𐑦𐑟
𐑷𐑤 𐑞 𐑑𐑧𐑒𐑕𐑑.</div></body></html>
