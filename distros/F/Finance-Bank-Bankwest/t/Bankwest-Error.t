use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;

use Finance::Bank::Bankwest::Error ();

run_tests(
    undef,
    't::lib::Test::UnexpectedParamFails' => { class => 'Error' },
);

test 'correct subclass' => sub {
    isa_ok 'Finance::Bank::Bankwest::Error', 'Throwable::Error';
};

test 'show message when stringified' => sub {
    throws_ok
        {
            Finance::Bank::Bankwest::Error
                ->throw( message => 'something went wrong' );
        }
        qr/something went wrong/;
};

{
    package t::CustomError1;
    use parent 'Finance::Bank::Bankwest::Error';
    sub MESSAGE { 'something went wrong' }

    package t::CustomError2;
    use parent 'Finance::Bank::Bankwest::Error';
    sub MESSAGE { die 'this should not be called' }
}

test 'show message when set via MESSAGE' => sub {
    throws_ok { t::CustomError1->throw } qr/something went wrong/,
        'message must be displayed';
};

test 'MESSAGE must be lazy' => sub {
    lives_ok { t::CustomError2->new };
};

run_me;
done_testing;
