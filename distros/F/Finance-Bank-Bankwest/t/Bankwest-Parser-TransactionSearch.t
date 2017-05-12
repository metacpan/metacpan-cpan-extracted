use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;

use Finance::Bank::Bankwest::Parser::TransactionSearch ();
use HTTP::Response ();

with 't::lib::Util::ResponseFixtures';

run_tests(
    undef,
    't::lib::Test::Parser' => {
        parser      => 'TransactionSearch',
        test_fail   => {
            'txn-search'    => 'ExportFailed::UnknownReason',
        },
    },
);

for (
    {
        input   => 'bad account',
        html    => 'txn-search-bad-acct',
        errors  => ['Please select an account for your search.'],
        params  => ['account'],
    },
    {
        input   => 'bad "from" date',
        html    => 'txn-search-bad-from-date',
        errors  => ['Please enter a date range.', 'Invalid Date'],
        params  => ['from_date'],
    },
    {
        input   => 'bad "to" date',
        html    => 'txn-search-bad-to-date',
        errors  => ['Please enter a date range.', 'Invalid Date'],
        params  => ['to_date'],
    },
    {
        input   => 'too-early "to" date',
        html    => 'txn-search-early-to-date',
        errors  => ["'Date To' must be later than 'Date From'"],
        params  => ['to_date'],
    },
    {
        input   => 'future "from" date',
        html    => 'txn-search-future-from-date',
        errors  => ['From date cannot be greater than the current date - MSGKA389.'],
        params  => [],  # BOB doesn't mark the form field in this case
    },
    {
        input   => 'too-early "from" date',
        html    => 'txn-search-from-date-outside-range',
        errors  => ['Date is outside valid date range'],
        params  => ['from_date'],
    },
    {
        input   => 'bad "from" and "to" dates',
        html    => 'txn-search-bad-dates',
        errors  => ['Please enter a date range.', 'Invalid Date'],
        params  => ['from_date', 'to_date'],
    },
    {
        input   => 'bad account, "from" and "to" dates',
        html    => 'txn-search-bad-acct-from-date-to-date',
        errors  => ['Please select an account for your search.', 'Invalid Date'],
        params  => ['account', 'from_date', 'to_date'],
    },
) {
    my $test = $_;
    my $desc = 'throw correct exception on ' . $test->{'input'};
    test $desc => sub {
        my $self = shift;
        my $response = $self->response_for( $test->{'html'} );
        throws_ok
            {
                Finance::Bank::Bankwest::Parser::TransactionSearch
                    ->new( response => $response )->handle;
            }
            'Finance::Bank::Bankwest::Error::ExportFailed';
        my $e = $@;
        is_deeply
            [$e->errors],
            $test->{'errors'},
            'correct reasons must be returned';
        is_deeply
            [sort $e->params],
            [sort @{ $test->{'params'} }],
            'correct parameters must be returned';
    };
}

run_me;
done_testing;
