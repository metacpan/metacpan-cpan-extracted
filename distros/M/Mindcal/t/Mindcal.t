
use Test::More tests => 5;
use Mindcal;

use Mindcal;
use DateTime;

my $mc = Mindcal->new(
  date => DateTime->new(
      day   => 1,
      month => 1,
      year  => 2000,
  )
);

is($mc->year_item(), 0, "year item");
is($mc->month_item(), 0, "month item");
is($mc->day_item(), 1, "day item");
is($mc->adjust(), 5, "adjust");
is($mc->weekday(), "Saturday", "weekday");
