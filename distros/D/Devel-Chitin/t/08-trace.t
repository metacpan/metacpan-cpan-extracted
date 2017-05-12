#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';
use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
run_in_debugger();

Devel::Chitin::TestDB->attach();
Devel::Chitin::TestDB->trace(1);

12;
my $i = 0;
while ($i < 2) {
    foo();
} continue {
    $i++;
}
19;
sub foo {
    21;
}

BEGIN {
    if (is_in_test_program) {
        eval "use Test::More tests => 20;";
    }
}

package Devel::Chitin::TestDB;
use base 'Devel::Chitin';
my @trace;
BEGIN {
    @trace = (
        { package => 'main', subroutine => 'MAIN', line => 12, filename => __FILE__ },
        { package => 'main', subroutine => 'MAIN', line => 13, filename => __FILE__ },
        # for loop condition
        { package => 'main', subroutine => 'MAIN', line => 14, filename => __FILE__ },
        # about to call foo()
        { package => 'main', subroutine => 'MAIN', line => 15, filename => __FILE__ },
        { package => 'main', subroutine => 'main::foo', line => 21, filename => __FILE__ },
        # continue
        { package => 'main', subroutine => 'MAIN', line => 17, filename => __FILE__ },
        # About to call foo() again
        { package => 'main', subroutine => 'MAIN', line => 15, filename => __FILE__ },
        { package => 'main', subroutine => 'main::foo', line => 21, filename => __FILE__ },
        # continue
        { package => 'main', subroutine => 'MAIN', line => 17, filename => __FILE__ },
        # done
        { package => 'main', subroutine => 'MAIN', line => 19, filename => __FILE__ },
    );
}

my $last_trace_loc;
sub notify_trace {
    my($class, $loc) = @_;

    my $next_test = shift @trace;
    exit unless $next_test;

    if (Devel::Chitin::TestRunner::has_callsite() and ! $loc->callsite) {
        ok(0, 'Callsite missing for line '.$next_test->{line});
    }
    delete $loc->{callsite}; # Can't test for any particular value
    Test::More::is_deeply($loc, $next_test, 'Trace for line '.$next_test->{line});
    $last_trace_loc = $loc;
}

sub notify_trace_resumed {
    my($class, $loc) = @_;
    Test::More::is_deeply($loc, $last_trace_loc, 'notify_trace_resumed for line '.$last_trace_loc->line);
}

