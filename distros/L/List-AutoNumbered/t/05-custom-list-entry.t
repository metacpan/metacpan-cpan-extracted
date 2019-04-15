#!perl
use 5.006;
use lib::relative '.';
use MY::Kit;

my $dut;

# Named arguments can be given in either order
$dut = $DUT->new(-how => sub {}, -at =>42);
isa_ok($dut, $DUT);

# Simulate the default "how" function
$dut = $DUT->new(-at => 42,
    -how => sub {
        shift unless defined $_[0];
        [@_]
    }
);
isa_ok($dut, $DUT);

$dut->load(1337);
is_deeply($dut->arr, [ [43, 1337] ], 'Adding an element also adds next number');

$dut->load(1338);
is_deeply($dut->arr, [ [43, 1337], [44, 1338] ], 'Adding another element also adds next number');

$dut->load(LSKIP 1, 1339);
is_deeply($dut->arr, [ [43, 1337], [44, 1338], [46, 1339] ], 'Adding after skip skips number');

$dut->add(1340);
is_deeply($dut->arr, [ [43, 1337], [44, 1338], [46, 1339], [1340] ], q(add doesn't add line number));

# Flatten everything
$dut = $DUT->new(-at => 42,
    -how => sub {
        shift unless defined $_[0];
        @_
    }
);
isa_ok($dut, $DUT);

$dut->load(1337);
is_deeply($dut->arr, [ 43, 1337 ], 'flatten: Adding an element also adds next number');

$dut->load(1338);
is_deeply($dut->arr, [ 43, 1337, 44, 1338 ], 'flatten: Adding another element also adds next number');

$dut->load(LSKIP 1, 1339);
is_deeply($dut->arr, [ 43, 1337, 44, 1338, 46, 1339 ], 'flatten: Adding after skip skips number');

$dut->add(1340);
is_deeply($dut->arr, [ 43, 1337, 44, 1338, 46, 1339, 1340 ], q(flatten: add doesn't add line number));

# Make a hashref of each element
$dut = $DUT->new(-at => 42,
    -how => sub {
        my $rv = {};
        my $lineno = shift;
        $rv->{line} = $lineno if defined $lineno;
        $rv->{data} = [@_];
        return $rv;
    }
);
isa_ok($dut, $DUT);

$dut->load(1337);
is_deeply($dut->arr, [ {line=>43, data=>[1337]} ],
    'hashref: Adding an element also adds next number');

$dut->load(1338);
is_deeply($dut->arr, [ {line=>43, data=>[1337]}, {line=>44, data=>[1338]} ],
    'hashref: Adding another element also adds next number');

$dut->load(LSKIP 1, 1339);
is_deeply($dut->arr, [ {line=>43, data=>[1337]}, {line=>44, data=>[1338]},
                        {line=>46, data=>[1339]} ],
    'hashref: Adding after skip skips number');

$dut->add(1340);
is_deeply($dut->arr, [ {line=>43, data=>[1337]}, {line=>44, data=>[1338]},
                        {line=>46, data=>[1339]}, {data=>[1340]} ],
    q(hashref: add doesn't add line number));

$dut->load(1..4);
is_deeply($dut->arr, [  {line=>43, data=>[1337]}, {line=>44, data=>[1338]},
                        {line=>46, data=>[1339]}, {data=>[1340]},
                        {line=>48, data=>[1..4]} ],
    q(hashref: load multiple items));

$dut->add(5..8);
is_deeply($dut->arr, [  {line=>43, data=>[1337]}, {line=>44, data=>[1338]},
                        {line=>46, data=>[1339]}, {data=>[1340]},
                        {line=>48, data=>[1..4]}, {data=>[5..8]} ],
    q(hashref: add multiple items));

num_is($dut->last_number, 49, 'add increments number');

done_testing;
