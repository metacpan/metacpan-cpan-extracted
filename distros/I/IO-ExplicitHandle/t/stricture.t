use warnings;
use strict;

use Test::More tests => 92;

BEGIN { $^H |= 0x20000; }

my $r;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { print 123; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in print /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { print STDOUT 123; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { print(123); }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in print /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { print(STDOUT 123); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { printf 123; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in printf /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { printf STDOUT 123; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { printf(123); }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in printf /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { printf(STDOUT 123); }
	1;
});
is $r, 1;
is $@, "";

SKIP: {
	skip "no say on this Perl", 8 unless "$]" >= 5.009003;

	$r = eval(q{
		use IO::ExplicitHandle;
		use feature "say";
		if(0) { say 123; }
		1;
	});
	is $r, undef;
	like $@, qr/\AUnspecified I\/O handle in say /;

	$r = eval(q{
		use IO::ExplicitHandle;
		use feature "say";
		if(0) { say STDOUT 123; }
		1;
	});
	is $r, 1;
	is $@, "";

	$r = eval(q{
		use IO::ExplicitHandle;
		use feature "say";
		if(0) { say(123); }
		1;
	});
	is $r, undef;
	like $@, qr/\AUnspecified I\/O handle in say /;

	$r = eval(q{
		use IO::ExplicitHandle;
		use feature "say";
		if(0) { say(STDOUT 123); }
		1;
	});
	is $r, 1;
	is $@, "";
}

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { close; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in close /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { close STDOUT; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { close(); }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in close /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { close(STDOUT); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { write; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in write /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { write STDOUT; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	my $h = "STDOUT";
	if(0) { write $h; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { write(); }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in write /;

$r = eval(q{
	use IO::ExplicitHandle;
	my $h = "STDOUT";
	if(0) { write($h); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { write(STDOUT); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { eof; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in eof /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { eof STDIN; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { eof(); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { eof(STDIN); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { tell; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in tell /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { tell STDIN; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { tell(); }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in tell /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { tell(STDIN); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { my $x = $|; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\| /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { $| = 0; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\| /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { my $x = $^; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\^ /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { $^ = 0; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\^ /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { my $x = $~; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\~ /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { $~ = 0; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\~ /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { my $x = $=; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\= /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { $= = 0; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\= /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { my $x = $-; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\- /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { $- = 0; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\- /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { my $x = $%; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\% /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { $% = 0; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\% /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { my $x = $.; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\. /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { $. = 0; }
	1;
});
is $r, undef;
like $@, qr/\AUnspecified I\/O handle in \$\. /;

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { my $x = $/; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use IO::ExplicitHandle;
	if(0) { $/ = 0; }
	1;
});
is $r, 1;
is $@, "";

1;
