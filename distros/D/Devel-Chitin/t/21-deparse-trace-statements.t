use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(has_callsite db_trace db_continue do_test);

$DB::single=1;
9;
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

sub __tests__ {
    my @expected = (
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

    if (has_callsite) {
        plan tests => scalar(@expected) * 3;
    } else {
        plan skip_all => 'Devel::Callsite is not installed';
    }

    db_trace(1);
    db_continue();

    for (my $i = 0; $i < @expected; $i++) {
        my $n = $i;
        my($expected_next_statement, $expected_next_fragment, $expected_next_parent_frag) = @{$expected[$i]};
        do_test {
            my $location = shift;
            my $line = $location->line;

            is(TestHelper->next_statement,
               $expected_next_statement,
               "next_statement() $n for line $line") || print_errors($location);

            is(TestHelper->next_fragment,
               $expected_next_fragment,
               "next_fragment() $n for line $line") || print_errors($location);

            is(TestHelper->next_fragment(1),
               $expected_next_parent_frag,
               "next_fragment() parent $n for line $line") || print_errors($location);
        };
    }
}

sub print_errors {
    my $loc = shift;
    diag(sprintf("stopped at line %d callsite 0x%0x\n", $loc->line, $loc->callsite));
    diag(Devel::Chitin::OpTree->build_from_location($loc)->print_as_tree($loc->callsite));
}
