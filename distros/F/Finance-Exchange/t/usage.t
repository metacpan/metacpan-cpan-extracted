use strict;
use warnings;
use Test::More;
use Test::Deep;
use Finance::Exchange;

my $exchange = Finance::Exchange->create_exchange('LSE');
is $exchange->symbol, 'LSE';
is $exchange->display_name, 'London Stock Exchange';
is $exchange->trading_days, 'weekdays';
is $exchange->trading_timezone, 'Europe/London';
# The list of days starts on Sunday and is a set of flags indicating whether
# we trade on that day or not
cmp_deeply $exchange->trading_days_list, [ 0, 1, 1, 1, 1, 1, 0 ];
is $exchange->delay_amount, 15, 'LSE minimum delay is 15 minutes';
is $exchange->currency, 'GBP', 'LSE is traded in pound sterling';
is $exchange->trading_date_can_differ, 0, 'only applies to AU/NZ';

done_testing;
