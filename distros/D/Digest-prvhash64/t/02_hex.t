use strict;
use warnings;
use Test::More;

use Digest::prvhash64 qw(
	prvhash64_hex
	prvhash64_64m_hex
);

my $msg = "hello world";

# Test hex helper
my $hx16_a = prvhash64_hex($msg, 16, 777);
my $hx16_b = prvhash64_hex($msg, 16, 777);
my $hx16_c = prvhash64_hex($msg, 16, 778);
ok(defined $hx16_a && $hx16_a =~ /^[0-9a-f]+$/i, 'hex output format');
is(length($hx16_a), 32, 'hex length is 2x hash_len');
is($hx16_a, $hx16_b, 'hex deterministic with same seed');
isnt($hx16_a, $hx16_c, 'hex changes with different seed');

$msg  = '123';
my $seed = 0;
is(prvhash64_hex($msg, 8, $seed), '034b6d7a5b6993ef');
is(prvhash64_hex($msg, 16, $seed), 'd76eea0ede81ea1ac05932078165fdb5');
is(prvhash64_hex($msg, 24, $seed), 'ea66379a3c093e58ff3c30e37bc0bb9542984db660396f7d');
is(prvhash64_hex($msg, 32, $seed), '4df816760366a28f32e1cc53c9d752cbed376e7a8c513a4fbde5cb8c0b178de4');
is(prvhash64_hex($msg, 64, $seed), '061004019eb97bdce985a96de918593028515872e581ae82a73b0561226c8ce93b5469d9c4250aec33a85e853156492030244cae6d247d1414b213437535b1eb');

$seed = 999;
is(prvhash64_hex($msg, 8, $seed), '6032f7851e1824bb');
is(prvhash64_hex($msg, 16, $seed), '073abfc92ea44910860eccd08e7e0df8');
is(prvhash64_hex($msg, 24, $seed), 'ad9cf30016b89e32b65736a34030e386cef21648864eb20b');
is(prvhash64_hex($msg, 32, $seed), 'ef67318045ecf9b244e58c523d2b6affa0c893af8d543cf78181f45c55ddd5cf');
is(prvhash64_hex($msg, 64, $seed), 'cef4ef9630ff916efd57bc4fc7bd815ae7ea726670d50d4c908d0ffcf51e00da04dda27434d3d8b62b842e54d050a6ca7ca31febb872fbf6f70211efa05baaf8');

$seed = 0;
is(prvhash64_64m_hex('123'  , $seed), 'ef93695b7a6d4b03');
is(prvhash64_64m_hex('456'  , $seed), '20e8dbf7742b1729');
is(prvhash64_64m_hex(''     , $seed), 'ec4c625cd9d6f2cf');
is(prvhash64_64m_hex('Hello', $seed), 'f134aa6a53f834d3');

$seed = 16129539322125092974;
is(prvhash64_64m_hex('123'  , $seed), 'f3439dd918193e65');
is(prvhash64_64m_hex('456'  , $seed), 'bd0b3de15c813159');
is(prvhash64_64m_hex(''     , $seed), '2de3c05d47359320');
is(prvhash64_64m_hex('Hello', $seed), '99db542321b8538b');

done_testing();
