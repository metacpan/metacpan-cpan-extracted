#!/usr/local/bin/perl -w

# Version: $Id: absolutizer.t 3 2007-10-05 15:49:42Z sergey.chernyshev $

use strict;
use Test;
BEGIN { plan tests => 6}

print "Testing if HTML::LinkChanger is available ... \n";
use HTML::LinkChanger;
ok(1);

print "Testing if HTML::LinkChanger::Absolutizer is available ... \n";
use HTML::LinkChanger::Absolutizer;
ok(1);

print "Testing if creation without base URL fails ... \n";
eval {
	new HTML::LinkChanger::Absolutizer();
};
ok($@=~/^Must specify base URL/);

print "Testing if creation with base URL succeeds ... \n";
my $absolutizer = new HTML::LinkChanger::Absolutizer(base_url => 'http://www.yahoo.com/images/index.html');
ok($absolutizer);

print "Testing if changer is created OK with Absolutizer filter \n";
my $changer = new HTML::LinkChanger(url_filters => [$absolutizer]);
ok($changer);

my $in = '<a href="http://www.google.com/"><img src="/image.gif"></a><img src="someotherimage.jpg">';
my $out = '<a href="http://www.google.com/"><img src="http://www.yahoo.com/image.gif"></a><img src="http://www.yahoo.com/images/someotherimage.jpg">';

print "Testing if input is returned as is if no filters supplied ... \n";

ok($changer->filter($in), $out);


