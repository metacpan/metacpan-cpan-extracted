use strict;
use warnings;
use Test::More;

use Inline 'CPP';


is_deeply(
    [ return_list() ], [ 1, 'Hello?', '15.75' ],
    "Return on the stack a list containing an int, a string, and a double."
);

# We used to test ok( $list[2], 15.6 ) with a corresponding value in the
# CPP function.  But because .6 cannot be represented in a finite number of
# binary digits we were getting some inequality test failures.
# 15.75 is the same as 126/8, which can be represented accurately in base 2.
# The goal of the test is to see if we're able to pass floating point values
# correctly, not to test the way a given C++ compiler handles floating point
# math.

is( return_void(), undef, "Void function that returns nothing." );

done_testing();

__END__
__CPP__

void return_list() {
    Inline_Stack_Vars;
    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSViv(1)));
    Inline_Stack_Push(sv_2mortal(newSVpv("Hello?",0)));
    Inline_Stack_Push(sv_2mortal(newSVnv(15.75)));
    Inline_Stack_Done;
}

void return_void() {
    printf("# Hello! from return_void()\n");
}
