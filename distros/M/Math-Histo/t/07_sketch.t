use Test2::V0;
use Math::Histo::Sketch;

subtest 'DDSketch online dynamic quantile sketch' => sub {
    my $sketch = Math::Histo::Sketch->new(alpha => 0.01, max_bins => 1024);
    isa_ok $sketch, 'Math::Histo::Sketch';
    is $sketch->num_entries, 0, 'empty sketch';
    is $sketch->total_weight, 0.0, 'zero weight';

    # Insert uniform sequence 1..1000
    my @vals = (1..1000);
    $sketch->insert_n(\@vals);
    is $sketch->num_entries, 1000, '1000 entries';
    is $sketch->total_weight, 1000.0, 'total weight 1000';

    # Packed binary insertion
    my $packed_extra = pack('d*', 1001.0, 1002.0);
    ok $sketch->insert_packed_f64($packed_extra), 'insert_packed_f64';
    is $sketch->num_entries, 1002, '1002 entries';

    is $sketch->min, 1.0, 'min is 1.0';
    is $sketch->max, 1002.0, 'max is 1002.0';


    # Quantiles with <= 1% relative error
    my $p50 = $sketch->quantile(0.50);
    is $p50, within(500.0, 500.0 * 0.02), 'p50 within relative error';

    my $p90 = $sketch->quantile(0.90);
    is $p90, within(900.0, 900.0 * 0.02), 'p90 within relative error';

    my $p99 = $sketch->quantile(0.99);
    is $p99, within(990.0, 990.0 * 0.02), 'p99 within relative error';

    # Merge sketches
    my $sketch2 = Math::Histo::Sketch->new(alpha => 0.01);
    my @vals2 = (1001..2000);
    $sketch2->insert_n(\@vals2);

    ok $sketch->merge($sketch2), 'merge sketch2 into sketch';
    is $sketch->num_entries, 2002, '2002 entries after merge';
    is $sketch->max, 2000.0, 'max is 2000.0';

    # Binary serialization
    my $blob = $sketch->serialize_binary;
    ok defined($blob) && length($blob) > 0, 'serialize_binary generated blob';

    my $restored = Math::Histo::Sketch->from_binary($blob);
    isa_ok $restored, 'Math::Histo::Sketch';
    is $restored->num_entries, 2002, 'restored 2002 entries';

};

done_testing;
