use Test::Routine;
use Test::Routine::Util;
use Test::More;

use Finance::Bank::Bankwest::Error::ExportFailed::UnknownReason ();
use HTTP::Response ();
use Scalar::Util 'refaddr';

my $r = HTTP::Response->new;

run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'ExportFailed::UnknownReason',
        parent  => 'ExportFailed',
        args    => { response => $r },
        text    => 'declined to export transactions for an unknown reason',
    },
);

run_tests(
    undef,
    't::lib::Test::UnexpectedParamFails' => {
        class       => 'Error::ExportFailed::UnknownReason',
        good_args   => { response => $r },
    },
);

test 'succeed with single argument' => sub {
    my $c = Finance::Bank::Bankwest::Error::ExportFailed::UnknownReason
        ->new($r);
    is refaddr $r, refaddr $c->response,
        'response should return the right response';
};
run_me;

done_testing;
