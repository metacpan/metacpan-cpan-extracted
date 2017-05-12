use lib 'tlib';
use Test::More tests => 2;

subtest 'Outermost scope' => sub {
    {
        use Test_Compiletime_Hints 'outermost';

        BEGIN{ Test_Compiletime_Hints::verify_hint_is('outermost'); }
        Test_Compiletime_Hints::verify_hint_is('outermost');

        subtest 'Middle scope' => sub {
            use Test_Compiletime_Hints 'middle';
            Test_Compiletime_Hints::verify_hint_is('middle');

            subtest 'Innermost scope' => sub {
                use Test_Compiletime_Hints 'innermost';
                Test_Compiletime_Hints::verify_hint_is('innermost');
            };

            Test_Compiletime_Hints::verify_hint_is('middle');
        };

        Test_Compiletime_Hints::verify_hint_is('outermost');
    }
    Test_Compiletime_Hints::verify_hint_is(undef);
};

done_testing();
