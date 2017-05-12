#!perl -w

use Test::More tests => 6;
use URI::URL;
use strict;
use Mail::SpamAssassin::SpamCopURI;
use Mail::SpamAssassin::PerMsgStatus;;
use Mail::SpamAssassin::Conf;;

my $conf = Mail::SpamAssassin::Conf->new;

my $known_bad_uri_1 = 'http://127.0.0.2/fo/bar';
my $known_bad_uri_2 = 'http://surbl-org-permanent-test-point.com/blah/xxx';

my $good_uri_1 = 'http://reallyfoobar.com/foo/bar';
my $good_uri_2 = 'http://www.google.com/blah/blah';

my $msg = Mail::SpamAssassin::PerMsgStatus->new();
$msg->{main} = Mail::SpamAssassin->new;
$msg->{conf} = $conf;

my @rbl_config = qw(sc.surbl.org 127.0.0.2);

ok($msg->check_spamcop_uri_rbl([$known_bad_uri_1], @rbl_config) == 1, "known bad uri1: $known_bad_uri_1 hit uri");
ok($msg->check_spamcop_uri_rbl([$known_bad_uri_2], @rbl_config) == 1, "known bad uri2: $known_bad_uri_2 hit uri");

$conf->add_to_addrlist ('whitelist_spamcop_uri', ('surbl-org-permanent-test-point.com'));


$msg->{conf} = $conf;

ok($msg->check_spamcop_uri_rbl([$known_bad_uri_1], @rbl_config) == 1, "known bad uri 1: $known_bad_uri_1 hit uri");

ok($msg->check_spamcop_uri_rbl([$known_bad_uri_2], @rbl_config) == 0, "known bad uri2: $known_bad_uri_2 miss uri");

ok($msg->check_spamcop_uri_rbl([$good_uri_1, $good_uri_1], @rbl_config) == 0, "$good_uri_1 uri miss");
ok($msg->check_spamcop_uri_rbl([$good_uri_2, $good_uri_2], @rbl_config) == 0, "$good_uri_2 uri miss");

