#!/usr/bin/perl -T

use strict; use warnings;

use Test::More tests => 21;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::Implementation'; }
package HTML::DOM::Implementation; our $it; package main; # fake import

# -------------------------#
# Tests 2-21: hasFeature

for (qw/html hTML/) {
	ok $it->hasFeature($_ => '1.0'), qq'hasFeature("$_","1.0")';
	ok!$it->hasFeature($_ => '3.0'), qq'hasFeature("$_","3.0")';
	ok $it->hasFeature($_),          qq'hasFeature("$_")';
}
ok!$it->hasFeature('exeotuht.cg.');
ok!$it->hasFeature('etg.d.h', '1.0');
ok!$it->hasFeature('nuthotgud,gd',haonuhoentuh=>);

ok$it->hasFeature('core','1.0'), 'core 1';
ok$it->hasFeature('core','2.0'), 'core 2';
ok$it->hasFeature('views','2.0'), 'views 2';
ok$it->hasFeature('html','2.0'), 'html 2';
ok$it->hasFeature('events','2.0'), 'events 2';
ok$it->hasFeature('uIevents','2.0'), 'uIevents 2';
ok$it->hasFeature('mouseevents','2.0'), 'mouseevents 2';
ok$it->hasFeature('mutationevents','2.0'), 'mutantevents 2';

++$INC{'CSS/DOM.pm'};
sub CSS::DOM::hasFeature { join '-', @_ }
is $it->hasFeature('stylesheets','2.0'), 'CSS::DOM-stylesheets-2.0',
	'hasFeature(stylesheets)';
is $it->hasFeature('css','2.0'), 'CSS::DOM-css-2.0',
	'hasFeature(css)';
is $it->hasFeature('css2','2.0'), 'CSS::DOM-css2-2.0',
	'hasFeature(css2)';
