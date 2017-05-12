use Test::Routine;
use Test::Routine::Util;
use Test::More;

use Finance::Bank::Bankwest::Error::BadResponse ();
use HTTP::Response ();
use Scalar::Util 'refaddr';

my $r = HTTP::Response->new;

run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'BadResponse',
        parent  => '',
        args    => { response => $r },
        text    => 'returned an unexpected response',
    },
);

run_tests(
    undef,
    't::lib::Test::UnexpectedParamFails' => {
        class       => 'Error::BadResponse',
        good_args   => { response => $r },
    },
);

test 'succeed with single argument' => sub {
    my $c = Finance::Bank::Bankwest::Error::BadResponse->new($r);
    is refaddr $r, refaddr $c->response,
        'response should return the right response';
};
run_me;

done_testing;
