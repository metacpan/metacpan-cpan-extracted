#!perl -w

use Test::More tests => 4;
use Mail::SpamAssassin::SpamCopURI;
use Mail::SpamAssassin::PerMsgStatus;;
use Mail::SpamAssassin::Conf;;
use strict;


my $conf = Mail::SpamAssassin::Conf->new;


$conf->add_to_addrlist ('blacklist_spamcop_uri', ('*mythingisgood.com', '*.something.really.com'));

my $msg = Mail::SpamAssassin::PerMsgStatus->new();

$msg->{conf} = $conf;
$msg->{main} = Mail::SpamAssassin->new;

my @bad_uri = qw(
  http://www.mythingisgood.com/foo/bar
  http://foo.something.really.com/foo/bar
);

my @good_uri = qw(
  http://really.com/foo/bar
  http://www.google.com/foo/bar
);


my @rbl_config = qw(sc.surbl.org 127.0.0.2);

ok($msg->check_spamcop_uri_rbl([$bad_uri[0]], @rbl_config) == 1, "$bad_uri[0] uri hit");
ok($msg->check_spamcop_uri_rbl([$bad_uri[1]], @rbl_config) == 1, "$bad_uri[1] uri hit");


ok($msg->check_spamcop_uri_rbl([$good_uri[0]], @rbl_config) == 0, "$good_uri[0] uri miss");
ok($msg->check_spamcop_uri_rbl([$good_uri[1]], @rbl_config) == 0, "$good_uri[1] uri miss");


