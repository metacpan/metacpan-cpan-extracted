use Test::More   tests => 2;
use Devel::StealthDebug emit_type => 'carp';
use File::Temp "tempfile";

my $foo;

my ($fh,$fn) = tempfile() or die $!;
close STDERR;
open (STDERR, "> $fn") or die $!;

eval {
	$foo = 42;#!emit(emit ok)!
	$foo++;
};

close STDERR;

ok($foo == 43);

open (STDIN,"< $fn");
my $out	=<STDIN>;
close STDIN;

like($out, qr/emit ok/);
