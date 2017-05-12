#!perl
use Devel::StackBlech qw( dumpStacks );

function();

sub function {
    eval {
        for ( 1 .. 1 ) {
            Devel::StackBlech::dumpStacks();
        }
    };
}
