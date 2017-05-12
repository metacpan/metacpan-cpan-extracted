#!/usr/bin/perl -T
# taint mode is to override idiomatic PERL5OPT=-MFIXME, and other attrocities

use strict;
use warnings;

use Test::More tests => 9;
use Test::Warn;
use Test::Exception;

sub Devel::FIXME::rules { sub { Devel::FIXME::DROP() } };
use_ok("Devel::FIXME");

use lib 't/lib';

throws_ok {
	require Devel::FIXME::Test::Error;
} qr{syntax error at t/lib/Devel/FIXME/Test/Error.pm line 6, near "if this is "\nCompilation failed in require at @{[ __FILE__ ]} line @{[ __LINE__ -1 ]}}, "syntax errors propegate ordinarily";

throws_ok {
	Devel::FIXME->new(qw/uneven number of elements in argument list/);
} qr/^Invalid arguments/, "can't construct a fixme with a weird argument list";

lives_ok {
	Devel::FIXME->readfile("t/lib/does_not_exist");
} "readfile on something nonexistent doesn't complain";

SKIP: {
	chmod 0, "t/lib/cant_read";
	skip "Won't generate error, because file is readable", 1 if -r "t/lib/cant_read";
	require Errno;
	Errno->import("EACCES");
	$! = EACCES();
	my $perm = "$!";

	throws_ok {
		Devel::FIXME->readfile("t/lib/cant_read");
	} qr/$perm/o, "readfile on something restricted yields permission denied";

	chmod 0644, "t/lib/cant_read";
}

unshift @INC, "t/lib/empty";

warning_is {
	require Text::Soundex;
} { carped => "FIXME's magic sub is no longer first in \@INC at " . __FILE__ . " line " . __LINE__ }, "\@INC sub not first, instead scalar";

my $called;
$INC[0] = sub { $called = 1 };

warning_is {
	require Class::ISA;
} { carped => "FIXME's magic sub is no longer first in \@INC at " . __FILE__ . " line " . __LINE__ }, "\@INC sub not first, instead other sub";

ok($called, "other sub was called");

throws_ok {
	Devel::FIXME->import(text => 'foo');
} qr/"text" is not exported by the Devel::FIXME module/, "importing a KVP list breaks";

