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

	my $comp = 'Shll';

	if (!$Mac::OSA::Simple::ScriptComponents{$comp}) {
		skip "OSA script component '$comp' not installed", 3;
	}

	my $osa = compile_osa_script($comp, 'ls');

	ok($osa,                       "compile");
	is($osa->execute, scalar `ls`, "list file");
	is($osa->source, 'ls',         "source");
}


__END__
