use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Permission;

subtest 'bit flags' => sub {
	is(Execute, 1, 'Execute is 1');
	is(Write,   2, 'Write is 2');
	is(Read,    4, 'Read is 4');
};

subtest 'bit combinations' => sub {
	my $rwx = Read | Write | Execute;
	is($rwx, 7, 'rwx is 7');

	my $rw = Read | Write;
	is($rw, 6, 'rw is 6');

	my $rx = Read | Execute;
	is($rx, 5, 'rx is 5');

	ok($rwx & Read,    'rwx includes Read');
	ok($rwx & Write,   'rwx includes Write');
	ok($rwx & Execute, 'rwx includes Execute');
	ok(!($rw & Execute), 'rw excludes Execute');
};

subtest 'mask constants' => sub {
	is(OwnerRead,     256, 'OwnerRead is 256');
	is(OwnerWrite,    128, 'OwnerWrite is 128');
	is(OwnerExecute,   64, 'OwnerExecute is 64');
	is(GroupRead,      32, 'GroupRead is 32');
	is(GroupWrite,     16, 'GroupWrite is 16');
	is(GroupExecute,    8, 'GroupExecute is 8');
	is(OtherRead,       4, 'OtherRead is 4');
	is(OtherWrite,      2, 'OtherWrite is 2');
	is(OtherExecute,    1, 'OtherExecute is 1');
};

subtest 'mask combinations' => sub {
	my $mode_755 = OwnerRead | OwnerWrite | OwnerExecute | GroupRead | GroupExecute | OtherRead | OtherExecute;
	is($mode_755, 0755, '755 mode');

	my $mode_644 = OwnerRead | OwnerWrite | GroupRead | OtherRead;
	is($mode_644, 0644, '644 mode');
};

subtest 'meta accessors' => sub {
	my $bit_meta = Bit();
	is($bit_meta->count, 3, '3 permission bits');
	ok($bit_meta->valid(1), 'Execute (1) is valid');
	ok($bit_meta->valid(4), 'Read (4) is valid');

	my $mask_meta = Mask();
	is($mask_meta->count, 9, '9 mask constants');
};

done_testing;
