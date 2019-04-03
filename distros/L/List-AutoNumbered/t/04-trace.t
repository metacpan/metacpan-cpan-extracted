#!perl
# Tests with TRACE on - for coverage, and to make sure it lives OK.
use 5.006;
use strict;
use warnings;
use lib::relative '.';
use Test::More;

{ # Test manually setting TRACE
    package T1;
    use 5.006;
    use lib::relative '.';
    use MY::Kit;
    use Test::Fatal;

    $List::AutoNumbered::TRACE = 1;

    my $dut;

    ok(!defined exception {
        $dut = List::AutoNumbered->new;
    }, 'new succeeds');

    ok(!defined exception {
        $dut->load(100);
    }, 'load succeeds');
    is_deeply($dut->arr, [ [1, 100] ], 'load worked');

    ok(!defined exception {
        $dut->add(101);
    }, 'add succeeds');
    is_deeply($dut->arr, [ [1, 100], [101] ], 'add worked');
    num_is($dut->last_number, 2, 'add incremented number');

    ok(!defined exception {
        $dut->load(LSKIP 2, 102);
    }, 'add succeeds');
    is_deeply($dut->arr, [ [1, 100], [101], [5, 102] ], 'load+skip worked');
    num_is($dut->last_number, 5, 'load+skip incremented number');

} #package T1

{ # Test importing TRACE
    package T2;     # Not using MY::Kit
    use 5.006;
    use Test::More;
    use Test::Fatal;
    use List::AutoNumbered qw(LSKIP *TRACE);

    $TRACE = 1;

    my $dut;

    ok(!defined exception {
        $dut = List::AutoNumbered->new;
    }, 'new succeeds');

    ok(!defined exception {
        $dut->load(100);
    }, 'load succeeds');
    is_deeply($dut->arr, [ [1, 100] ], 'load worked');

    ok(!defined exception {
        $dut->add(101);
    }, 'add succeeds');
    is_deeply($dut->arr, [ [1, 100], [101] ], 'add worked');
    cmp_ok($dut->last_number, '==', 2, 'add incremented number');

    ok(!defined exception {
        $dut->load(LSKIP 2, 102);
    }, 'add succeeds');
    is_deeply($dut->arr, [ [1, 100], [101], [5, 102] ], 'load+skip worked');
    cmp_ok($dut->last_number, '==', 5, 'load+skip incremented number');

} #package T2

{ # Test importing TRACE via :all
    package T3;     # Not using MY::Kit
    use 5.006;
    use Test::More;
    use Test::Fatal;
    use List::AutoNumbered ':all';

    $TRACE = 1;

    my $dut;

    ok(!defined exception {
        $dut = List::AutoNumbered->new;
    }, 'new succeeds');

} #package T3

done_testing;

__END__

# Skipper
my $dut = LSKIP 1;
my $S = $DUT . '::Skipper';
isa_ok($dut, $S);
$dut = LSKIP "42";      # OK as long as it looks_like_number
isa_ok($dut, $S);

# List::AutoNumbered
$dut = $DUT->new;       # No parameters
isa_ok($dut, $DUT);

$dut = $DUT->new(42);   # With parameters
isa_ok($dut, $DUT);

# Initial members
num_is($dut->size, 0, 'Zero size initially');
num_is($dut->last, -1, '$# == -1 initially');
is_deeply($dut->arr, [], 'Empty array initially');

# Loads
$dut->load(1337);
is_deeply($dut->arr, [ [43, 1337] ], 'Adding an element also adds next number');
num_is($dut->size, 1, 'size 1 after add');
num_is($dut->last, 0, '$# == 0 after add');

$dut->load(1338);
is_deeply($dut->arr, [ [43, 1337], [44, 1338] ], 'Adding another element also adds next number');
num_is($dut->size, 2, 'size 2 after add 2');
num_is($dut->last, 1, '$# == 1 after add 2');

# skips

$dut->load(LSKIP 1, 1339);
is_deeply($dut->arr, [ [43, 1337], [44, 1338], [46, 1339] ], 'Adding after skip skips number');
num_is($dut->size, 3, 'size 3 after add 3');
num_is($dut->last, 2, '$# == 2 after add 3');

$dut->load(LSKIP 9, 1340);
is_deeply($dut->arr, [ [43, 1337], [44, 1338], [46, 1339], [56, 1340] ], 'Adding after skip skips numbers');
num_is($dut->size, 4, 'size 4 after add 4');
num_is($dut->last, 3, '$# == 3 after add 4');

# add()

$dut->add(200);     # without skip
is_deeply($dut->arr, [ [43, 1337], [44, 1338], [46, 1339], [56, 1340], [200] ],
    q(add() doesn't add line number));
num_is($dut->size, 5, 'size 5 after add');
num_is($dut->last_number, 57, 'add() does bump the number');

$dut->add(LSKIP 19, 201);   # with skip
is_deeply($dut->arr, [ [43, 1337], [44, 1338], [46, 1339], [56, 1340], [200],
                        [201] ],
    q(add() with skip doesn't add line number));
num_is($dut->size, 6, 'size 6 after add with skip');
num_is($dut->last_number, 77, 'add() with skip does bump the number');

$dut->load(202);
is_deeply($dut->arr, [ [43, 1337], [44, 1338], [46, 1339], [56, 1340], [200],
                        [201], [78, 202] ],
    q(load after add() with skip does add line number));
num_is($dut->size, 7, 'size 7 after load after add with skip');

# Load with references
$dut = $DUT->new;
$dut->load([1],[2]);
is_deeply($dut->arr, [
        [ 1, [1], [2] ]
    ], 'Accepts references'
);

done_testing;
