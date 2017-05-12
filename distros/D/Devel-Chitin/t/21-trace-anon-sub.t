#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';
use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
run_in_debugger();

Devel::Chitin::TestDB->attach();
Devel::Chitin::TestDB->trace(1);

sub {
    my $a = shift;
    my $b = 2;
    $a + $b;
}->(1);
my $done = "done\n";;

BEGIN {
    if (is_in_test_program) {
        if (Devel::Chitin::TestRunner::has_callsite) {
            eval "use Test::More tests => 5;";
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
        join("\n",  'sub {',
                    "\t" . '$a = shift;',
                    "\t" . '$b = 2;',
                    "\t" . '$a + $b',
                    '}->(1)'),
        '$a = shift',
        '$b = 2',
        '$a + $b',
        '$done = "done\n"',
    );
}

sub notify_trace {
    my($class, $loc) = @_;
    my $line = $loc->line;

    my $expected_next_statement = shift @trace;
    exit unless $expected_next_statement;

    my $next_statement = $class->next_statement();
    Test::More::is($next_statement, $expected_next_statement, "next_statement for line $line")
        || print_errors($loc);
}

sub print_errors {
    my $loc = shift;
    Test::More::diag(sprintf("stopped at line %d callsite 0x%0x\n", $loc->line, $loc->callsite));
    Test::More::diag(Devel::Chitin::OpTree->build_from_location($loc)->print_as_tree($loc->callsite));
}
