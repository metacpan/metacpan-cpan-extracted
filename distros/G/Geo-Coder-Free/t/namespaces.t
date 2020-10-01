#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

if($ENV{RELEASE_TESTING}) {
	eval {
		require Test::CleanNamespaces;
	};
	if($@) {
		plan(skip_all => 'Test::CleanNamespaces not installed');
	} else {
		Test::CleanNamespaces->all_namespaces_clean();
	}
} else {
	plan(skip_all => "Author tests not required for installation");
}
