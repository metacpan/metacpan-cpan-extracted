#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';
use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
run_in_debugger();

Devel::Chitin::TestDB->attach();
Devel::Chitin::TestDB->trace(1);

my $answer = fib(3);
sub fib {
    my $n = shift;
    return 1 if $n <= 1;
    return fib($n - 1) + fib($n - 2);
}

BEGIN {
    if (is_in_test_program) {
        if (Devel::Chitin::TestRunner::has_callsite) {
            eval "use Test::More tests => 13;";
        } else {
            eval "use Test::More skip_all => 'Devel::Callsite is not available'";
        }
    }
}

package Devel::Chitin::TestDB;
use base 'Devel::Chitin';
my @trace;
BEGIN {
    @trace = (
        '$answer = fib(3)',
        # in fib()
        '$n = shift',
        'return(1) if $n <= 1',
        'return(fib($n - 1) + fib($n - 2))',
        # recurse for fib(2)  "fib($n - 1)"
        '$n = shift',
        'return(1) if $n <= 1',
        'return(fib($n - 1) + fib($n - 2))',
        # recurse for fib(1)  "fib($n - 1)"
        '$n = shift',
        'return(1) if $n <= 1',
        # recurse for fib(0)  "fib($n - 2)"
        '$n = shift',
        'return(1) if $n <= 1',
        # back to recurse for fib(0)  "fib($n - 2)
        '$n = shift',
        'return(1) if $n <= 1',
    );
}

sub notify_trace {
    my($class, $loc) = @_;

    my $expected_next_statement = shift @trace;
    exit unless $expected_next_statement;

    my $next_statement = $class->next_statement();
    Test::More::is($next_statement, $expected_next_statement, 'next_statement for line '.$loc->line)
        || do {
            Test::More::diag(sprintf("stopped at line %d callsite 0x%0x\n", $loc->line, $loc->callsite));
            Test::More::diag(Devel::Chitin::OpTree->build_from_location($loc)->print_as_tree($loc->callsite));
        };
}

