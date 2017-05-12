#!perl -w

use Test::More tests => 7;
use URI::URL;
use strict;
use Mail::SpamAssassin::SpamCopURI;
use Mail::SpamAssassin::PerMsgStatus;;
use Mail::SpamAssassin::Conf;;

my $conf = Mail::SpamAssassin::Conf->new;
my $msg = Mail::SpamAssassin::PerMsgStatus->new();
$msg->{main} = Mail::SpamAssassin->new;
$msg->{conf} = $conf;

ok($msg->check_spamcop_uri_rbl(['http://surbl-org-permanent-test-point.com/good/'], 'sc.surbl.org', '127.0.0.2'), 'test rbl is bad');

ok($msg->check_spamcop_uri_rbl(['http://foo.bar.xxx.yyy.surbl-org-permanent-test-point.com/foo'], 'sc.surbl.org', '127.0.0.2'), 'test rbl is bad with random stuff');

ok($msg->check_spamcop_uri_rbl(['http://foo.bar.xxx.yyy.test.google.com/foo'], 'sc.surbl.org', '127.0.0.2') == 0, 'google test is good with random stuff');

ok($msg->check_spamcop_uri_rbl(['http://127.0.0.1/blah'], 'sc.surbl.org', '127.0.0.2') == 0, 
'Loopback address is okay');

ok($msg->check_spamcop_uri_rbl(['http://127.0.0.2/baddy'], 'sc.surbl.org', '127.0.0.2'), 
   'known bad address is bad');

ok($msg->check_spamcop_uri_rbl(['http://google.com/groups'], 'sc.surbl.org', '127.0.0.2') == 0, 'google is okay');

ok($msg->check_spamcop_uri_rbl(['http://www.google.com', 'http://www.yahoo.com', 'http://surbl-org-permanent-test-point.com/good/'], 'sc.surbl.org', '127.0.0.2'), 'test rbl is bad in array');

