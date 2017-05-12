use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'ExportFailed',
        parent  => '',
        args    => { params => ['A'], errors => [] },
        text    => 'rejected transaction parameter/s [A]',
    },
);
run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'ExportFailed',
        parent  => '',
        args    => { params => [qw{ A B C }], errors => [] },
        text    => 'rejected transaction parameter/s [A, B, C]',
    },
);
run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'ExportFailed',
        parent  => '',
        args    => { params => [], errors => ['oh no', 'oops'] },
        text    => "reason/s:\n  * oh no\n  * oops",
    },
);
done_testing;
