package Devel::AutoInit;

BEGIN {
	push @ISA, 'Devel::DebugHooks';
}

use Devel::DebugHooks();

print $DB::dbg;

1;
