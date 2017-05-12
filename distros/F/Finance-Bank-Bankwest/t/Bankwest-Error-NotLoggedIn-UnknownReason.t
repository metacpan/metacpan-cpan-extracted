use Test::Routine;
use Test::Routine::Util;
use Test::More;

use Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason ();
use HTTP::Response ();
use Scalar::Util 'refaddr';

my $r = HTTP::Response->new;

run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'NotLoggedIn::UnknownReason',
        parent  => 'NotLoggedIn',
        args    => { response => $r },
        text    => 'cannot be established for an unknown reason',
    },
);

run_tests(
    undef,
    't::lib::Test::UnexpectedParamFails' => {
        class       => 'Error::NotLoggedIn::UnknownReason',
        good_args   => { response => $r },
    },
);

test 'succeed with single argument' => sub {
    my $c = Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason
        ->new($r);
    is refaddr $r, refaddr $c->response,
        'response should return the right response';
};
run_me;

done_testing;
