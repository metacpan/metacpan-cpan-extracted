#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN {
	plan tests => 26;
	use_ok('Mac::OSA::Simple');
}

use Mac::OSA::Simple 1.02;

use File::Basename;
use File::Spec::Functions 'catfile';


my @path = fileparse($0, '\..+');
my $file = catfile($path[1], $path[0]);
unlink $file if -e $file;

END {
	unlink $file if -e $file;
}

SKIP: {
#	skip "Mac::OSA::Simple", 11;

	my $osa1 = compile_applescript(<<EOS);
property foo: 0
set foo to foo + 1
return foo
EOS

	ok($osa1,              "compile");
	is($osa1->execute, 1,  "execute (1)");
	ok($osa1->save($file), "save");

	ok(-e $file,   "file exists");
	if ($^O eq 'MacOS') {
		ok(! -s $file, "no data fork");
	} else {
		is(-s $file, length($osa1->compiled->get), "data fork is length of handle data");
	}

	my $osa2 = load_osa_script($osa1->compiled);
	ok($osa2,             "clone");
	is($osa2->execute, 2, "execute (2)");

	like($osa2->source, qr/set foo to foo \+ 1/, "source");
	is($osa1->source,   $osa2->source,           "source");

	ok($osa1->dispose, "dispose");
	ok($osa2->dispose, "dispose");
}


SKIP: {
#	skip "Mac::OSA::Simple", 14;

	my $osa3 = load_osa_script($file);
	ok($osa3,              "load");
	is($osa3->execute, 2,  "execute (2)");
	is($osa3->execute, 3,  "execute (3)");
	is($osa3->execute, 4,  "execute (4)");
	ok($osa3->save($file), "save");

	my $osa4 = load_osa_script($file);
	ok($osa4,              "load");
	is($osa4->execute, 5,  "execute (5)");
	is($osa4->execute, 6,  "execute (6)");
	is($osa4->execute, 7,  "execute (7)");

	is($osa3->execute, 5,  "execute (5)");
	is($osa3->execute, 6,  "execute (6)");
	is($osa3->execute, 7,  "execute (7)");

	ok($osa3->dispose, "dispose");
	ok($osa4->dispose, "dispose");
}

__END__
