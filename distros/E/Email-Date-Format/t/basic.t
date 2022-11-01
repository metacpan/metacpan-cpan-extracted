use Test::More tests => 7;
use strict;
$^W = 1;

use Email::Date::Format qw(email_date email_gmdate);

is(
  length email_date, # no argument == now
  (localtime)[3] > 9 ? 31 : 30, # Day > 9 means extra char in the string
  "constant length",
);

my $birthday = 1153432704; # no, really!

sub tz($) { sprintf "%s%02u%02u", Email::Date::Format::_tz_diff(shift) }

local $ENV{TZ} = "UTC+4";
my $tz = tz(1153432704);

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

my $badyear = 1900 + ((gmtime)[5] - 49) % 100;
my $badt = Time::Local::timegm(0, 0, 0, 1, 0, $badyear);
$ENV{TZ} = "UTC-11";
is(tz($badt - 60), "+1100", "positive timezone before year rollover");
is(tz($badt + 60), "+1100", "positive timezone after year rollover");
$ENV{TZ} = "UTC+9";
is(tz($badt - 60), "-0900", "negative timezone before year rollover");
is(tz($badt + 60), "-0900", "negative timezone after year rollover");
