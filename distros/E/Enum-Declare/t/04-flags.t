use strict;
use warnings;
use Test::More;

use_ok('Enum::Declare');

# basic :Flags — powers of 2
{
	package Perms;
	use Enum::Declare;

	enum Perms :Flags { Read, Write, Execute };
}

is(Perms::Read(),    1, 'Read is 1');
is(Perms::Write(),   2, 'Write is 2');
is(Perms::Execute(), 4, 'Execute is 4');

my $meta = Perms::Perms();
isa_ok($meta, 'Enum::Declare::Meta');
is($meta->count, 3, 'count is 3');
is_deeply($meta->values, [1, 2, 4], 'values are powers of 2');

# bitwise operations
my $rw = Perms::Read() | Perms::Write();
is($rw, 3, 'Read | Write is 3');
ok($rw & Perms::Read(),    'rw has Read');
ok($rw & Perms::Write(),   'rw has Write');
ok(!($rw & Perms::Execute()), 'rw does not have Execute');

my $all = Perms::Read() | Perms::Write() | Perms::Execute();
is($all, 7, 'all permissions is 7');

# more flags to verify continued doubling
{
	package Events;
	use Enum::Declare;

	enum Events :Flags { Click, Hover, Focus, Blur, Scroll };
}

is(Events::Click(),  1,  'Click is 1');
is(Events::Hover(),  2,  'Hover is 2');
is(Events::Focus(),  4,  'Focus is 4');
is(Events::Blur(),   8,  'Blur is 8');
is(Events::Scroll(), 16, 'Scroll is 16');

# :Flags with explicit start value
{
	package Bits;
	use Enum::Declare;

	enum Bits :Flags { A = 4, B, C };
}

is(Bits::A(), 4,  'A is 4 (explicit)');
is(Bits::B(), 8,  'B is 8 (shifted from 4)');
is(Bits::C(), 16, 'C is 16 (shifted from 8)');

done_testing();
