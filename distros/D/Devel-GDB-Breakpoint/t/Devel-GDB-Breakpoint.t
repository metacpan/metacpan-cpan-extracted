use Test::More;

use Devel::GDB::Breakpoint;

ok(breakpoint 5, 'breakpoint set');

done_testing;
