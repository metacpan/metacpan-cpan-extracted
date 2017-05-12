######################################################################
# Test suite for Gaim::Log::Parser
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
use Gaim::Log::Parser;

my $EG = "eg";
$EG = "../eg" unless -d $EG;

use Test::More;

plan tests => 16;

my $canned = "$EG/canned/proto/from_user/to_user/2005-10-29.230219.txt";

my $p = Gaim::Log::Parser->new(
    file      => $canned,
    time_zone => "America/Los_Angeles",
);

my $msg = $p->next_message();

my $epoch = $msg->date();
is($epoch, "1130652143", "Check Epoch in LA timezone");

$p = Gaim::Log::Parser->new(
    file      => $canned,
    time_zone => "America/Chicago",
);

$msg = $p->next_message();
$epoch = $msg->date();
is($epoch, "1130644943", "Check Epoch in Chicago timezone");

# Offline-Messages 
$canned = "$EG/canned/proto/from_user/to_user/2005-10-29.230220.txt";

$p = Gaim::Log::Parser->new(
    file      => $canned,
    time_zone => "America/Los_Angeles",
);
$msg = $p->next_message();
$epoch = $msg->date();
is($epoch, "1154239445", "Explicit date given");

$msg = $p->next_message();
$epoch = $msg->date();
is($epoch, "1154325788", "Rollover after explicit date");

$canned = "$EG/canned/proto/from_user/to_user/2005-10-29.230221.txt";

$p = Gaim::Log::Parser->new(
    file      => $canned,
    time_zone => "Europe/Berlin",
);
$msg = $p->next_message();
is($msg->date(), "1148782440", "Date in European format");
is($msg->content(), "abc def", "Message string");

$msg = $p->next_message();
is($msg->date(), "1148782441", "Date in American format");
is($msg->content(), "ghi jkl", "Message string");

$msg = $p->next_message();
is($msg->date(), "1148782442", "Date in American format 2-digit year");
is($msg->content(), "mno pqr", "Message string");

$msg = $p->next_message();
is($msg->date(), "1148782443", "Date in European format 2-digit year");
is($msg->content(), "stu vwx", "Message string");

$msg = $p->next_message();
is($msg->date(), "1148782444", "No date, just time");
is($msg->content(), "yza bcd", "Message string");

$msg = $p->next_message();
is($msg->date(), "1194554680", "EU date/time");
is($msg->content(), "und wie isses?", "Message string");
