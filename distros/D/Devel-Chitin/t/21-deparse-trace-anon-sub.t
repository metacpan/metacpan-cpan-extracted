use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(has_callsite db_trace db_continue do_test);

$DB::single=1;
9;
sub {
    my $a = shift;
    my $b = 2;
    $a + $b;
}->(1);
my $done = "done\n";

sub __tests__ {
    my @expected = (
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

    if (has_callsite) {
        plan tests => scalar(@expected);
    } else {
        plan skip_all => 'Devel::Callsite is not installed';
    }

    db_trace(1);
    db_continue;

    for (my $i = 0; $i < @expected; $i++) {
        my $n = $i;
        my $expected = $expected[$i];
        do_test {
            my $location = shift;
            my $next_statement = TestHelper->next_statement;
            is($next_statement, $expected, "statement $n")
                || print_errors($location);
        };
    }
}

sub print_errors {
    my $loc = shift;
    diag(sprintf("stopped at line %d callsite 0x%0x\n", $loc->line, $loc->callsite));
    diag(Devel::Chitin::OpTree->build_from_location($loc)->print_as_tree($loc->callsite));
}
