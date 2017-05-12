#########################

use Test::More tests => 11;

sub BEGIN {
use_ok('Games::Hack::Patch::i686');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# not a real example, instruction would be longer.
# just testing if a NOP would be issued.
$bin=GetNOP(5,6, 'mov eax,$1');
is($bin, "\x90", "NOP");

$bin=GetNOP(5,10, 'mov eax,$1');
is($bin, "\xeb\x03", "Simply short jump");

$bin=GetNOP(5,11, 'fstps +20(%ebp)');
is($bin, "\xdf\xc0\xeb\x02", "Floating point store 1");

$bin=GetNOP(5,10, 'fstp +20(%ebp)');
is($bin, "\xdf\xc0\xeb\x01", "Floating point store 2");
$bin=GetNOP(5,10, 'fst +20(%ebp)');
is($bin, "\xeb\x03", "Floating point store without pop");

$bin=GetNOP(10,14, 'popl [esi]');
is($bin, "\x83\xc4\x04\x90", "Pop from stack");


$has_warned=0;
eval { 
	local %SIG;
	$SIG{'__WARN__'} = sub { $has_warned++ };

	$bin=GetNOP(5,10, 'xxx'); 
};
is($bin, undef, "Unknown instructions are not simply patched");
is($has_warned, 1, "Unknown instructions are warned about");


{ TODO: {
	local $TODO="SIMD/MMX ops not done yet";
	local %SIG;
	$SIG{'__WARN__'} = sub { };

# is that an sse instruction?
	$bin=GetNOP(5,10, 'psubsw');
	is($bin, "", "SIMD/MMX op");
} }

ok("finished");

