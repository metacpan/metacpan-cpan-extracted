use strict; use warnings; use diagnostics;
use FindBin '$Bin';
use lib $Bin;
use Test::More;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

is(add(3, 7), 10, 'string syntax');
is(subtract(3, 7), -4, 'string syntax again');
is(multiply(3, 7), 21, 'DATA syntax');
is(divide(7, -3), -2, 'DATA syntax again');

use Inline 'C';
use Inline C => 'DATA';
use Inline C => <<'END_OF_C_CODE';

int add(int x, int y) {
    return x + y;
}

int subtract(int x, int y) {
    return x - y;
}
END_OF_C_CODE

Inline->bind(C => <<'END');

int incr(int x) {
    return x + 1;
}
END

is(incr(incr(7)), 9, 'Inline->bind() syntax');

done_testing;

__END__

# unused code or maybe AutoLoader stuff
sub crap {
    return 'crap';
}

__C__

int multiply(int x, int y) {
    return x * y;
}

__C__

int divide(int x, int y) {
    return x / y;
}
