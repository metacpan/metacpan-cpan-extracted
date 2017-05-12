#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN {
	plan tests => 4;
	use_ok('Mac::OSA::Simple');
}

use Mac::OSA::Simple 1.02;
use Mac::Components;

SKIP: {
#	skip "Mac::OSA::Simple", 3;

	my $comp = 'Jscr';

	if (!$Mac::OSA::Simple::ScriptComponents{$comp}) {
		skip "OSA script component '$comp' not installed", 3;
	}

	my $script = 'myList = new Array ("foo", "bar", "baz");';
	my $osa = compile_osa_script($comp, $script);

	ok($osa,                         "compile");
	is($osa->execute, "foo,bar,baz", "get array");
	is($osa->source,  $script,       "source");
}


__END__
