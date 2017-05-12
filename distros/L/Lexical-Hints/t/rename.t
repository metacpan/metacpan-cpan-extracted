use lib 'tlib';
use Test::More tests => 2;

subtest 'Outermost scope' => sub {
    use Test_Renaming 'outermost';

    BEGIN{ Test_Renaming::verify_hint_is('outermost'); }
    Test_Renaming::verify_hint_is('outermost');

    subtest 'Middle scope' => sub {
        use Test_Renaming 'middle';
        Test_Renaming::verify_hint_is('middle');

        subtest 'Innermost scope' => sub {
            use Test_Renaming 'innermost';
            Test_Renaming::verify_hint_is('innermost');
        };

        Test_Renaming::verify_hint_is('middle');
    };

    Test_Renaming::verify_hint_is('outermost');
};

done_testing();

