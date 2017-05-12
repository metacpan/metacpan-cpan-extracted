use Test::More tests => 3;
use strict;
$^W = 1;

use Email::Date::Format qw(email_date email_gmdate);

is(
  length email_date, # no argument == now
  (localtime)[3] > 9 ? 31 : 30, # Day > 9 means extra char in the string
  "constant length",
);

my $birthday = 1153432704; # no, really!

my $tz = sprintf "%s%02u%02u", Email::Date::Format::_tz_diff(1153432704);

SKIP: {
    skip "test only useful in US/Eastern, -0400, not $tz", 1 if $tz ne '-0400';

    is(
        email_date(1153432704),
        'Thu, 20 Jul 2006 17:58:24 -0400',
        "rjbs's birthday date format properly",
    );
}

is(
  email_gmdate(1153432704),
  'Thu, 20 Jul 2006 21:58:24 +0000',
  "rjbs's birthday date format properly in GMT",
);
