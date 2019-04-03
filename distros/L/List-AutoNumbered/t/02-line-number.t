#!perl
use 5.006;
use lib::relative '.';
use MY::Kit;

#$List::AutoNumbered::TRACE=1;

# Test non-chained loads

my $lnum = __LINE__;                                                # $lnum...
#diag "\$lnum = $lnum";                                                  # +1
my $dut = $DUT->new($lnum+2);                                           # +2
isa_ok($dut, $DUT);                                                     # +3
                                                                        # +4
$dut->load(LSKIP 2, 42);                                                # +5
                                                                        # +6
num_is($dut->size, 1, 'size 1 after add');                              # +7
num_is($dut->last, 0, '$# == 0 after add');                             # +8
is_deeply($dut->arr, [ [$lnum+5, 42] ], 'Loads line number');           # +9
                                                                        # +10
$dut->load(LSKIP 5, 43);                                                # +11
is_deeply($dut->arr, [ [$lnum+5, 42], [$lnum+11, 43] ],                 # +12
    'Loads second line number');                                        # +13

# Chained load

$lnum = __LINE__;                                                   # $lnum...
$dut = List::AutoNumbered->new($lnum+1);                                # +1
$dut->load(100)->                                                       # +2
    (101)                                                               # +3
    (102)                                                               # +4
    (103)                                                               # +5
    (104)                                                               # +6
    (105);                                                              # +7

num_is($dut->size, 6, 'size 6 after chained load');
num_is($dut->last, 5, '$# == 5 after chained load');
is_deeply($dut->arr, [
        [$lnum+2, 100],
        [$lnum+3, 101],
        [$lnum+4, 102],
        [$lnum+5, 103],
        [$lnum+6, 104],
        [$lnum+7, 105],
    ],
    'Chained load worked'
);

# Chained load with skips

$lnum = __LINE__;                                                   # $lnum...
$dut = List::AutoNumbered->new($lnum+1);                                # +1
$dut->load(200)->                                                       # +2
    (201)                                                               # +3
        # A random comment line                                         # +4
    (LSKIP 1, 202)                                                      # +5
    (203)                                                               # +6
        # First of...                                                   # +7
        # ...two comment lines                                          # +8
    (LSKIP 2, 204)                                                      # +9
    (205);                                                              # +10

num_is($dut->size, 6, 'size 6 after chained load');
num_is($dut->last, 5, '$# == 5 after chained load');
is_deeply($dut->arr, [
        [$lnum+2, 200],
        [$lnum+3, 201],
        [$lnum+5, 202],
        [$lnum+6, 203],
        [$lnum+9, 204],
        [$lnum+10, 205],
    ],
    'Chained load with skips worked'
);

done_testing;
