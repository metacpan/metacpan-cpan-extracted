use v5.12.0;
use warnings;

use Test::More;

use Email::Date::Format qw(email_date email_gmdate);

is(
  length email_date, # no argument == now
  (localtime)[3] > 9 ? 31 : 30, # Day > 9 means extra char in the string
  "constant length",
);

my $birthday = 1153432704; # no, really!

is(
  email_gmdate($birthday),
  'Thu, 20 Jul 2006 21:58:24 +0000',
  "rjbs's birthday date format properly in GMT",
);

sub tz($) { sprintf "%s%02u%02u", Email::Date::Format::_tz_diff(shift) }

if ($^O ne 'MSWin32') {
  # https://github.com/rjbs/Email-Date-Format/issues/5
  #
  # Look, I'm not sure exactly what's going on here!  I think the short version
  # is "you can't set $TZ on Windows to make these tests go" and maybe it
  # hasn't worked in ages and I just didn't know.  Patches from better Windows
  # programmers than me are welcome! -- rjbs, 2023-01-13

  local $ENV{TZ} = "UTC+4";
  my $tz = tz(1153432704);

  SKIP: {
      if ($tz ne '-0400') {
        skip "test only useful in US/Eastern, -0400, not $tz", 1;
      }

      is(
          email_date(1153432704),
          'Thu, 20 Jul 2006 17:58:24 -0400',
          "rjbs's birthday date format properly",
      );
  }

  my $badyear = 1900 + ((gmtime)[5] - 49) % 100;
  my $badt = Time::Local::timegm_modern(0, 0, 0, 1, 0, $badyear);
  $ENV{TZ} = "UTC-11";
  is(tz($badt - 60), "+1100", "positive timezone before year rollover");
  is(tz($badt + 60), "+1100", "positive timezone after year rollover");
  $ENV{TZ} = "UTC+9";
  is(tz($badt - 60), "-0900", "negative timezone before year rollover");
  is(tz($badt + 60), "-0900", "negative timezone after year rollover");
}

done_testing;
