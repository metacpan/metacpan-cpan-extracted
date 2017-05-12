use Test::More tests => 24;
use lib qw(./blib/lib);
use HTTP::WebTest::Plugin::DateTest;

# time units parsing
$date = '1';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 1, "1 second: '$date' - returned '$ret'");

$date = '1 minute';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 60, "60 seconds: '$date' - returned '$ret'");

$date = '1    hr';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 3600, "3600 seconds: '$date' - returned '$ret'");

$date = '1 day -- additional text ignored';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 86400, "86400 seconds: '$date' - returned '$ret'");

$date = '    1 week -- leading space ignored';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 7*86400, "a week full of seconds: '$date' - returned '$ret'");

$date = '1 SECOND';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 1, "Case insensitive: '$date' - returned '$ret'");

$date = '1.5 hours';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 3600+1800, "Fractional value: '$date' - returned '$ret'");

$date = "\t1\thr";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 3600, "Tabs as whitespace: '$date' - returned '$ret'");

$date = '1 dada -- nonsense units';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 86400, "Unit interpreted as 'd': '$date' - returned '$ret'");

$date = '10 foobar -- utmost nonsense units';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 10, "Default unit is 'seconds': '$date' - returned '$ret'");

$date = 'not numeric 10';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 0, "Zero: '$date' - returned '$ret'");

$date = '.5 minutes';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 30, "Fraction only: '$date' - returned '$ret'");

$date = '+10 secs';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 10, "Leading plus: '$date' - returned '$ret'");

$date = '-10 secs';
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, -10, "Leading minus: '$date' - returned '$ret'");

$date = "\t+1.536 \t Hours (comment)\n1 more line";
$ret = &HTTP::WebTest::Plugin::DateTest::_str2seconds($date);
is($ret, 3600*1.536, "Baroque format: '$date' - returned '$ret'");

# reverse: date string rendering
$date = "987653"; # seconds
$ret = &HTTP::WebTest::Plugin::DateTest::_seconds2str($date);
is($ret, '1w 4d 10:20:53', "$date seconds: '$ret'");

$date = "987653"; # seconds
$ret = &HTTP::WebTest::Plugin::DateTest::_seconds2str($date, 'w');
is($ret, '1.63 w', "$date seconds: '$ret'");

$date = "987653"; # seconds
$ret = &HTTP::WebTest::Plugin::DateTest::_seconds2str($date, 'd');
is($ret, '11.43 d', "$date seconds: '$ret'");

$date = "7200"; # seconds
$ret = &HTTP::WebTest::Plugin::DateTest::_seconds2str($date, 'h');
is($ret, '2.00 h', "$date seconds: '$ret'");

$date = "200"; # seconds
$ret = &HTTP::WebTest::Plugin::DateTest::_seconds2str($date, 'm');
is($ret, '3.33 m', "$date seconds: '$ret'");

$date = "653.74"; # seconds
$ret = &HTTP::WebTest::Plugin::DateTest::_seconds2str($date, 's');
is($ret, '653.74 s', "$date seconds: '$ret'");

$date = "653.74"; # seconds
($ret) = &HTTP::WebTest::Plugin::DateTest::_seconds2str($date, 's');
is($ret, '653.74 s', "List context: $date seconds: '$ret'");

# invalid date value
$date = 'unknown';
($ret) = &HTTP::WebTest::Plugin::DateTest::_seconds2str($date);
is($ret, 'unknown', "Invalid date: $date : '$ret'");

$date = 'unanticipated';
($ret) = &HTTP::WebTest::Plugin::DateTest::_seconds2str($date);
is($ret, 'unknown', "Invalid date: $date : '$ret'");

