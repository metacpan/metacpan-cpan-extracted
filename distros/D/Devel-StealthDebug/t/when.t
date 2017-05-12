use Test::More   tests => 1;
#use Devel::StealthDebug SOURCE => '/tmp/source.txt';
use Devel::StealthDebug;

eval {
	close STDERR;
	my $foo = 1;#!watch($foo)!

	my $bar = 1 / $foo; #!when($foo,>,10)!

	$foo++;#!emit_type(croak)!
	$foo+=9;
};
like($@, qr/\$foo>10/);
