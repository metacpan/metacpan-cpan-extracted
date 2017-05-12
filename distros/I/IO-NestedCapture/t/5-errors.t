# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 27;

use IO::NestedCapture qw':constants :subroutines';

my $capture = IO::NestedCapture->instance;

eval {
	$capture->start(CAPTURE_NONE - 1);
};

ok($@, "Too small: $@");

eval {
	IO::NestedCapture->start(CAPTURE_ALL + 1);
};

ok($@, "Too big: $@");

{
	package Tie::Foo;

	sub TIEHANDLE { bless {} }
}

tie *STDIN, 'Tie::Foo';
isa_ok(tied *STDIN, 'Tie::Foo');
eval {
	$capture->start(CAPTURE_STDIN);
};

ok($@, "Already tied to something else: $@");

untie *STDIN;

eval {
	IO::NestedCapture->stop(CAPTURE_NONE - 1);
};

ok($@, "Too small: $@");

eval {
	$capture->stop(CAPTURE_ALL + 1);
};

ok($@, "Too big: $@");

eval {
	$capture->stop(CAPTURE_STDIN);
};

ok($@, "Not in use: $@");

eval {
	$capture->start(CAPTURE_STDIN);
	$capture->stop(CAPTURE_STDIN);
	$capture->stop(CAPTURE_STDIN);
};

ok($@, "Not in use: $@");

eval { capture_in { die "foo\n" }; };
ok($@, "capture_in died: $@");
is(tied *STDIN, undef);

eval { capture_out { die "foo\n" }; };
ok($@, "capture_out died: $@");
is(tied *STDOUT, undef);

eval { capture_err { die "foo\n" }; };
ok($@, "capture_err died: $@");
is(tied *STDERR, undef);

eval { capture_in_out { die "foo\n" }; };
ok($@, "capture_in_out died: $@");
is(tied *STDIN, undef);
is(tied *STDOUT, undef);

eval { capture_in_err { die "foo\n" }; };
ok($@, "capture_in_err died: $@");
is(tied *STDIN, undef);
is(tied *STDERR, undef);

eval { capture_out_err { die "foo\n" }; };
ok($@, "capture_out_err died: $@");
is(tied *STDOUT, undef);
is(tied *STDERR, undef);

eval { capture_all { die "foo\n" }; };
ok($@, "capture_all died: $@");
is(tied *STDIN, undef);
is(tied *STDOUT, undef);
is(tied *STDERR, undef);
