#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN { plan tests => 4 }

use Mac::Carbon qw(:resources :files :macperl);

SKIP: {
#	skip "Mac::Carbon", 4;
	ok(resChanged() == 2, 'resChanged() == 2');
	ok(defined &FSpGetCatInfo, 'FSpGetCatInfo imported');
	ok(!defined &RegisterComponentResource, 'RegisterComponentResource not imported');
	ok(DoAppleScript('get version'), 'DoAppleScript() works');
}

__END__
