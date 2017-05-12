#!perl -w

use Test::More tests => 1;
use Mail::SpamAssassin::SpamCopURI;
use Mail::SpamAssassin::PerMsgStatus;;


my $mailto_uri = 'mailto:aoeuaoeuxxx@aoeuaoeu.com';

my $msg = Mail::SpamAssassin::PerMsgStatus->new();


my @rbl_config = qw(sc.surbl.org 127.0.0.2);
ok($msg->check_spamcop_uri_rbl([$mailto_uri], @rbl_config) == 0, 
   'mailto is miss for host');

