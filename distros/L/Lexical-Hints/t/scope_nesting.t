use lib 'tlib';
use Test::More;

plan tests => 1;

subtest 'Outermost scope' => sub {
    use Test_Compiletime_Hints 'outermost';

    Test_Compiletime_Hints::verify_hint_is('outermost');

    subtest 'Middle scope gets outermost hint' => sub {
        use Test_Compiletime_Hints;
        Test_Compiletime_Hints::verify_hint_is('outermost');

        subtest 'Innermost scope' => sub {
            use Test_Compiletime_Hints 'innermost';
            Test_Compiletime_Hints::verify_hint_is('innermost');
        };

        use Test_Compiletime_Hints 'middle';
        Test_Compiletime_Hints::verify_hint_is('middle');
    };

    Test_Compiletime_Hints::verify_hint_is('outermost');
};

done_testing();

