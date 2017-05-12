use Test::More tests => 16;

# for testing purposes configure ourselves with specific timezone
use POSIX;
BEGIN {
    $ENV{TZ} = 'EST';
    POSIX::tzset();
};

use lib qw(./blib/lib);
use HTTP::WebTest::Plugin::DateTest;

# Tests for i10l date parsing
$date = 'ma 22 juli 2002, 14:05:44';
my $ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'dutch');
is($ret, 1027364744, "Dutch date '$date'");

$date = ' dinsdag  22 okt 2002   14:05 ';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'dutch');
is($ret, 1035313500, "Dutch date string with extra spaces '$date'");

$date = '22 oct 2002, 14:05:44';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'fReNcH');
is($ret, 1035313544, "'fReNcH' date '$date'");

$date = 'Mar 19 Mars 2002, 17:25';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'fReNcH');
is($ret, 1016576700, "French ambiguity '$date'");

$date = '19 Mär 2002 17:25';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'German');
is($ret, 1016576700, "German '$date'");

$date = <<"EOD";
 19 Mär
 2002 17:25
EOD
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'German');
is($ret, 1016576700, "Same, multiple lines");

# default date parsing
$date = 'Mon Jul 22 14:05:44 CEST 2002';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'English');
is($ret, 1027339544, "English date as returned by date(1) '$date'");

$date = 'Mon Jul 22 14:05:44 CEST 2002';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date);
is($ret, 1027339544, "Unspecified locale '$date'");

$date = "\t  Mon Jul 22 14:05:44 CEST 2002  ";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date);
is($ret, 1027339544, "Leading/trailing whitespace '$date'");

$date = "Mon Jul 22 14:05:44 CEST 2002 with nonsense";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date);
ok(! $ret, "Trailing text (does not parse) '$date'");

$date = "   19 Mär 2002 17:25\t";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'German');
is($ret, 1016576700, "German with leading/trailing space '$date'");

$date = "Ceci n'est pas une date: 99-33-3333";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date);
is($ret, undef, "No date string '$date'");

$date = "";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'Dutch');
is($ret, undef, "Empty string with locale '$date'");

$date = "";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date);
is($ret, undef, "Empty string, default '$date'");

$date = "no numbers (Locale)";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date, 'Dutch');
is($ret, undef, "No date string '$date'");

$date = "no numbers (default)";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2time_locale($date);
is($ret, undef, "No date string '$date'");

