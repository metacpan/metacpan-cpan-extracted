#!/usr/bin/perl -w

use strict;
use Test::More tests => 59;
use lib ".";
use HTML::Calendar::Simple;
use Date::Simple;

my $cal = HTML::Calendar::Simple->new;
my $today = Date::Simple->new;

isa_ok $cal, 'HTML::Calendar::Simple';
is $cal->month, $today->month, "month is correct (no args to new)";
is $cal->year,  $today->year,  "year is correct (no args to new)";
is $cal->_spacer, "", 'The _spacer value is correct';

$cal = HTML::Calendar::Simple->new({'month' => 1});
isa_ok $cal, 'HTML::Calendar::Simple';
is $cal->month, 1, "month is correct (month only to new)";
is $cal->year,  $today->year,  "year is correct (month only to new)";
is $cal->_spacer, "", 'The _spacer value is correct';

$cal = HTML::Calendar::Simple->new({'year' => 2001});
isa_ok $cal, 'HTML::Calendar::Simple';
is $cal->month, $today->month, "month is correct (year only to new)";
is $cal->year,  2001,  "year is correct (year only to new)";
is $cal->_spacer, "", 'The _spacer value is correct';

$cal = HTML::Calendar::Simple->new({'month' => 1, 'year' => 2001});
isa_ok $cal, 'HTML::Calendar::Simple';
is $cal->month, 1, "month is correct";
is $cal->year, 2001, "year is correct";
is $cal->_spacer, "", 'The _spacer value is correct';

my $string = $cal->html;
like $string, qr/table/, "the HTML string contains table";
unlike $string, qr/TESTDATA/, "the HTML string doesn't contain TESTDATA";
unlike $string, qr/href/, "there are no hrefs in the HTML string";

$cal->daily_info({ 'day'  => 12,
                   'info' => 'TESTDATA',
});

$string = $cal->html;
like $string, qr/TESTDATA/, "the HTML string now contains TESTDATA";
unlike $string, qr/href/, "there are no hrefs in the HTML string";

$cal->daily_info({ 'day'      => 7,
                   'day_link' => "a link",
});
$string = $cal->html;
like $string, qr/<a href=\"a link\">7<\/a>/, "the 7th is now an href";

$cal->daily_info({ 'day'  => 14,
                   'link' => 'http://www.stray-toaster.co.uk'
});
$string = $cal->html;
unlike $string, qr/HREFM/, "No separate link added";

$cal->daily_info({ 'day'  => 14,
                   'link' => ['http://www.stray-toaster.co.uk', 'My site'],
});
$string = $cal->html;
like $string, qr/<a href=\"http:\/\/www.stray-toaster.co.uk\">My site<\/a>/, 
  "HTML string now contains the link";
is $string, $cal->calendar_month, 
  "call calendar_month is actually the call html. What a country";
$string = $cal->calendar_month({nonsense => 'silliness'});
like $string, qr/border="1"/, 'Nonsense border args leave default size';
$string = $cal->calendar_month;
like $string, qr/border="1"/, 'No border args leave default size';
$string = $cal->calendar_month({border => 0});
like $string, qr/border="0"/, 'Border args give border size';

$string = "$cal";
unlike $string, qr/<a href=\"http:\/\/www.stray-toaster.co.uk\">My site<\/a>/, 
  "stringified doesn't contain the link";
unlike $string, qr/<a href=\"a link\">7<\/a>/, "stringified 7th is NOT an href";
unlike $string, qr/TESTDATA/, "stringified doesn't contain TESTDATA";

is $cal->picture, 0, "There is no pin-up";

$cal->pin_up("This would be a picture");
is $cal->picture, "This would be a picture", "There is now a pin-up";

my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my $year_cal = HTML::Calendar::Simple->calendar_year; # current year
my $year = $today->year;

like $year_cal, qr/$year/, "It is the correct year $year";
foreach my $month (@months) {
  like $year_cal, qr/$month/, " - year calendar contains $month";
}

$year--;
$year_cal = HTML::Calendar::Simple->calendar_year({ 'year' => $year });
like $year_cal, qr/$year/, "It is the correct year $year";
foreach my $month (@months) {
  like $year_cal, qr/$month/, " - year calendar contains $month";
}
