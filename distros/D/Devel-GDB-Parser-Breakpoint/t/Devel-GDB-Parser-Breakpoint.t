use Test::More;

use strict;
use warnings;

use Devel::GDB::Parser::Breakpoint;

# parser_breakpoint always returns 1
ok(parser_breakpoint 5, 'breakpoint set');

# Shouldn't choke either
parser_breakpoint 5;

my $x = 1;
if ($x == 1 && parser_breakpoint 5 && $x == 2 && $x == 3) {
}

done_testing;
