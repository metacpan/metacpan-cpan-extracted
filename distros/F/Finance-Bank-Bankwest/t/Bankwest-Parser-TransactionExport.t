use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::Parser' => {
        parser      => 'TransactionExport',
        parse_ok    => 'txn-export.csv',
        parse_type  => 'Transaction',
        parse       => [
            {
                date        => '02/04/2013',
                narrative   => 'AUTHORISATION ONLY - EFTPOS PURCHASE '
                                . 'AT SCHNITZ 203 ELIZABET   '
                                . 'MELBOURNE   AUSAU',
                amount      => '-33.00',
                type        => 'DAU',
                cheque_num  => undef,
            },
            {
                date        => '03/04/2013',
                narrative   => 'BUNNINGS COBURG 6310 REG 93',
                amount      => '-14.98',
                type        => 'CHQ',
                cheque_num  => '000000123',
            },
            {
                date        => '28/03/2013',
                narrative   => 'ENTERTAINMENT PUBL CROWS NEST AUS',
                amount      => '-74.00',
                type        => 'WDC',
                cheque_num  => undef,
            },
            {
                date        => '27/03/2013',
                narrative   => 'SALARY Job Pty Ltd',
                cheque_num  => undef,
                amount      => '1242.34',
                type        => 'PAY',
            },
            {
                date        => '25/03/2013',
                narrative   => 'PAYPAL AUSTRALIA XXXXXXXXXXXXX',
                cheque_num  => undef,
                amount      => '-355.00',
                type        => 'WDL',
            },
            {
                date        => '13/03/2013',
                narrative   => 'electricity bill',
                cheque_num  => undef,
                amount      => '-324.31',
                type        => 'TFD',
            },
            {
                date        => '27/02/2013',
                narrative   => 'ANZ ATM W/D TRAN FOR $60.00 ANZ ATM '
                                . 'OPERATOR FEE OF $2.00 PAID BY B/WEST',
                cheque_num  => undef,
                amount      => undef,
                type        => 'NAR',
            },
            {
                date        => '27/02/2013',
                narrative   => 'MELBOURNE (55) #5 MELBOURNE VI',
                cheque_num  => undef,
                amount      => '-60.00',
                type        => 'WDL',
            },
        ],
    },
);
done_testing;
