use Test::Routine;
use Test::Routine::Util;
use Test::More;

use Scalar::Util 'refaddr';

my %good_args = (
    date        => '31/12/2012',
    narrative   => '1 BANK CHEQUE FEE - BWA CUSTOMER',
    cheque_num  => undef,
    amount      => '-10.00',
    type        => 'FEE',
);

run_tests(
    undef,
    't::lib::Test::UnexpectedParamFails' => {
        class       => 'Transaction',
        good_args   => \%good_args,
    },
);

test 'equals method true' => sub {
    my $txn1 = Finance::Bank::Bankwest::Transaction->new( %good_args );
    my $txn2 = Finance::Bank::Bankwest::Transaction->new( %good_args );
    isnt refaddr $txn1, refaddr $txn2,
        'the two transactions must have separate references';
    ok $txn1->equals($txn2),
        'direct equals method call must return true';
    ok($txn1 eq $txn2, '"eq" operator must return true');
};

test 'equals method false' => sub {
    for (
        [ date          => '30/12/2012'     ],
        [ narrative     => 'SOMETHING ELSE' ],
        [ type          => undef            ],
        [ amount        => undef            ],
        [ amount        => '34.50'          ],
        [ cheque_num    => '000000123'      ],
    ) {
        my ($attr, $value) = @$_;
        my $txn1 = Finance::Bank::Bankwest::Transaction->new( %good_args );
        my $txn2 = Finance::Bank::Bankwest::Transaction->new(
            %good_args,
            $attr => $value,
        );
        ok ! $txn1->equals($txn2),
            "equals must return false for different '$attr' value";
        ok $txn1 ne $txn2,
            "'ne' must return true for different '$attr' value";
    }
};

test 'date_dt method' => sub {
    plan skip_all => 'DateTime not installed'
        if not eval { require DateTime; 1 };
    my $txn = Finance::Bank::Bankwest::Transaction->new( %good_args );
    is $txn->date_dt->strftime('%d/%m/%Y'), $txn->date,
        'DateTime date must match string date';
};

run_me;
done_testing;
