use lib 'tlib';
use Test::More;

plan tests => 2;

subtest 'Outermost scope' => sub {
    use Test_Compiletime_Hints 'outermost';

    Test_Compiletime_Hints::verify_hint_is('outermost');

    Test_Compiletime_Hints::set_hint_to('outerleast');
    Test_Compiletime_Hints::verify_hint_is('outerleast');

    subtest 'Middle scope' => sub {
        use Test_Compiletime_Hints 'middle';
        Test_Compiletime_Hints::verify_hint_is('middle');

        subtest 'Innermost scope' => sub {
            use Test_Compiletime_Hints 'innermost';
            Test_Compiletime_Hints::verify_hint_is('innermost');

            Test_Compiletime_Hints::set_hint_to('innerleast');
            Test_Compiletime_Hints::verify_hint_is('innerleast');
        };

        Test_Compiletime_Hints::verify_hint_is('middle');
    };

    Test_Compiletime_Hints::verify_hint_is('outerleast');
};

subtest 'Unautovivifiable hints' => sub {
    use Test_Compiletime_Hints 'vivified';
    Test_Compiletime_Hints::verify_hint_is('vivified');
    Test_Compiletime_Hints::set_new_hint_to('unvivified');
};

done_testing();
