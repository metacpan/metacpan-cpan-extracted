use Test::More;
use Test::LeakTrace;
use List::Flatten::XS 'flatten';

my $ref_1 = +{a => 10, b => 20, c => 'Hello'};
my $ref_2 = bless +{a => 10, b => 20, c => 'Hello'}, 'Nyan';
my $ref_3 = bless $ref_2, 'Waon';
my $pattern = [[[[[[[[[[[["foo"], "bar"], 3], "baz"], 5], $ref_1], "hoge"], $ref_2], "huga"], 1], "K"], $ref_3];

no_leaks_ok {
    flatten($pattern);
} 'Detected memory leak via flatten()';

no_leaks_ok {
    flatten($pattern, 3);
} 'Detected memory leak via flatten($ary, $level)';

done_testing;