use lib 'tlib';
use Test::More;

plan tests => 2;

subtest 'Hints should be set in this scope' => sub {
    use Test_Global_Hints;

    Test_Global_Hints::verify_set();

    subtest 'Hints should still be set in this scope' => sub {
        Test_Global_Hints::verify_set();
    };

    Test_Global_Hints::verify_set();
};

subtest 'Hints should NOT be set in this scope' => sub {
    Test_Global_Hints::verify_unset();

    subtest 'Hints should still NOT be set in this scope' => sub {
        Test_Global_Hints::verify_unset();
    };

    Test_Global_Hints::verify_unset();
};

done_testing();
