use warnings;
use strict;

BEGIN { unshift @INC, "./t/lib"; }
use Test::More tests => 15;

BEGIN { $^H |= 0x20000; }

ok eval("if(0) { print 123; } 1");
ok !eval("use IO::ExplicitHandle; if(0) { print 123; } 1");
ok eval("if(0) { print 123; } 1");
ok eval("{ use IO::ExplicitHandle; } if(0) { print 123; } 1");
ok eval(q{
	use IO::ExplicitHandle;
	no IO::ExplicitHandle;
	if(0) { print 123; }
	1;
});
ok !eval(q{
	use IO::ExplicitHandle;
	{ no IO::ExplicitHandle; }
	if(0) { print 123; }
	1;
});

SKIP: {
	skip "lexical hints don't propagate into eval on this perl", 7
		unless "$]" >= 5.009003;
	ok eval("if(0) { print 123; } 1");
	use IO::ExplicitHandle;
	ok !eval("if(0) { print 123; } 1");
	{
		ok !eval("if(0) { print 123; } 1");
		ok eval("no IO::ExplicitHandle; if(0) { print 123; } 1");
		ok !eval("if(0) { print 123; } 1");
		no IO::ExplicitHandle;
		ok eval("if(0) { print 123; } 1");
	}
	ok !eval("if(0) { print 123; } 1");
}

ok eval q{
	use IO::ExplicitHandle;
	use t::scope_0;
	1;
};

ok !eval q{
	use IO::ExplicitHandle;
	BEGIN { my $x = "foo\x{666}"; $x =~ /foo\p{Alnum}/; }
	if(0) { print 123; }
	1;
};

1;
