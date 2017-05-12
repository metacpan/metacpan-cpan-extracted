#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';
use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
run_in_debugger();

Devel::Chitin::TestDB->attach();
Devel::Chitin::TestDB->trace(1);

my $line = 12;
my $i = 0; my $b = 13;
while ($i < 2) {
    foo($i);
} continue {
    my $a = $i++;
}
$line = 19;
sub foo {
    $line = 21;
}
if (23 < $line) {
    $i = 24;
} else {
    $i = 26;
}
my @a = ( 28 );
map { $_ + 1 } ( 29, @a );

BEGIN {
    if (is_in_test_program) {
        if (Devel::Chitin::TestRunner::has_callsite) {
            eval "use Test::More tests => 51;";
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
        [ '$line = 12', '12',   '$line = 12' ],
        [ '$i = 0',     '0',    '$i = 0' ],
        [ '$b = 13',    '13',   '$b = 13' ],
        # while loop
        [   '$i < 2',
            '$i < 2',
            join("\n",  'while ($i < 2) {',
                    "\tfoo(\$i)",
                    '} continue {',
                    "\t\$a = \$i++",
                    '}'),
        ],
        # about to call foo()
        [ 'foo($i)',    'foo($i)',  '($i, foo)' ],
        [ '$line = 21', '21',       '$line = 21' ],
        # continue
        [ '$a = $i++',  '$i',       '$i++' ],
        # About to call foo() again
        [ 'foo($i)',    'foo($i)',  '($i, foo)' ],
        [ '$line = 21', '21',       '$line = 21' ],
        # continue
        [ '$a = $i++',  '$i',       '$i++' ],
        # done
        [ '$line = 19', '19',       '$line = 19' ],
        # if() condition
        [ '23 < $line', '23',       '23 < $line' ],
        [ '$i = 26',    '26',       '$i = 26'],
        [ '@a = 28',    '28',       '28' ],
        [ '29, @a',   'map',      'map' ],
        [ '$_ + 1',     '_',        '$_' ],
        [ '$_ + 1',     '_',        '$_' ],
    );
}

sub notify_trace {
    my($class, $loc) = @_;
    my $line = $loc->line;

    my $expected_next = shift @trace;
    exit unless $expected_next;

    my($expected_next_statement, $expected_next_fragment, $expected_next_parent_frag) = @$expected_next;

    my $next_statement = $class->next_statement();
    Test::More::is($next_statement, $expected_next_statement, "next_statement for line $line")
        || print_errors($loc);

    my $next_fragment = $class->next_fragment();
    Test::More::is($next_fragment, $expected_next_fragment, "next_fragment for line $line")
        || print_errors($loc);

    my $next_fragment_parent = $class->next_fragment(1);
    Test::More::is($next_fragment_parent, $expected_next_parent_frag, "next_fragment parent for line $line")
        || print_errors($loc);
}

sub print_errors {
    my $loc = shift;
    Test::More::diag(sprintf("stopped at line %d callsite 0x%0x\n", $loc->line, $loc->callsite));
    Test::More::diag(Devel::Chitin::OpTree->build_from_location($loc)->print_as_tree($loc->callsite));
}
