#!perl
use 5.006;
use lib::relative '.';
use MY::Kit;

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

$dut = $DUT->new(-at => 42);    # With named parameters
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

# Array deref
$dut = $DUT->new;
$dut->load(21)->(22)->(23);
is_deeply([ @$dut ], [ [1,21], [2,22], [3,23] ], 'Overloads array dereference');

done_testing;
