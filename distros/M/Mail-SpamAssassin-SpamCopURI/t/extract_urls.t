#!perl -w

use Test::More tests => 23;
use URI::URL;
use strict;
use Mail::SpamAssassin;
use Mail::SpamAssassin::Conf;
use Mail::SpamAssassin::PerMsgStatus;

my $conf = Mail::SpamAssassin::Conf->new;
my $msg = Mail::SpamAssassin::PerMsgStatus->new();
$msg->{main} = Mail::SpamAssassin->new;
$msg->{conf} = $conf;

my $google = 'http://images.google.ca/imgres?imgurl=gmib.free.fr/viagra.jpg&imgrefurl=https://www.google.com/url?q=http://www.google.com/url?q=%68%74%74%70%3A%2F%2F%77%77%77%2E%65%78%70%61%67%65%2E%63%6F%6D%2F%6D%61%6E%67%65%72%33%32';

my $g_msn_com = 'http://g.msn.com/0US!s5.22028_435065/HP.1001?%68ttp://www.vseidutvpizdu.com/p.htm';

my $rd_yahoo = 'http://rd.yahoo.com/M=977435.3841435.1410784.3050341/D=yahoo_top/S=0800288:LCC/A=8062671/R=0/*http://www.%72%65%61dyf%6F%72th%65d%65%61l%7A%2E%69%6Ef%6F%2F%78/?AFF%5FID=%78xoa045dmm&url=http://foo.bar.com';

my $ads_msn_com = 'http://ads.msn.com/ads/adredir.asp?image=/ads/IMGSFS/sjp6jhojtg7s45.gif&url=http://www.g%65t%69tn%6Fwb%65f%6Fr%65%69tsg%6Fn%65.%69nf%6F%2F%62/?AFF%5FID=%61%33ggc307xmc';

my $long_yahoo = 'http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar';


my $aol = "http://www.aol.com/ams/clickThruRedirect.adp?1=073757372,2147618210x2147531923,http://www.freeyouraccounts.com/stressfree/";

my $rd_yahoo_one_slash = "http://rd.yahoo.com/piteous/hairpin/catv/*http:/www.eloanlenders.com/?partid=3Darlenders5";

my $rd_yahoo_back_slash = 'http://rd.yahoo.com/piteous/hairpin/catv/*http:\www.google.com';

my $rd_yahoo_double_back_slash = 'http://rd.yahoo.com/piteous/hairpin/catv/*http:\\www.google.com';

my $rd_yahoo_half_back_slash = 'http://rd.yahoo.com/piteous/hairpin/catv/*http:\/www.google.com';

my $rd_yahoo_other_half_back_slash = 'http://rd.yahoo.com/piteous/hairpin/catv/*http:/\www.google.com';

sub test_extract {

  my $url = shift;

  my @expect = @_;

  push @expect, $url;

  my @urls = Mail::SpamAssassin::SpamCopURI::_extract_urls($url);

  ok(@urls == @expect, "got expected number of urls: for $url");


  ok(eq_set(\@urls, \@expect), 'got what we expected from the urls');

}

test_extract($aol, 'http://www.freeyouraccounts.com/stressfree/');

test_extract($google, 'https://www.google.com/url?q=http://www.google.com/url?q=http://www.expage.com/manger32',
                       'http://www.google.com/url?q=http://www.expage.com/manger32',
		       'http://www.expage.com/manger32');


test_extract($g_msn_com, 'http://www.vseidutvpizdu.com/p.htm');

test_extract($rd_yahoo, 'http://foo.bar.com', 'http://www.readyforthedealz.info/x/',);

test_extract($ads_msn_com, 'http://www.getitnowbeforeitsgone.info/b/?AFF_ID=a3ggc307xmc');

test_extract($long_yahoo, 'http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar',
          'http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar',
           'http://surbl-org-permanent-test-point.com/foo/bar',
          'http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar',
          'http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar' );


test_extract($rd_yahoo_one_slash, 'http://www.eloanlenders.com/');

test_extract($rd_yahoo_back_slash, 'http://www.google.com');

test_extract($rd_yahoo_double_back_slash, 'http://www.google.com');

test_extract($rd_yahoo_half_back_slash, 'http://www.google.com');

test_extract($rd_yahoo_other_half_back_slash, 'http://www.google.com');


ok($msg->check_spamcop_uri_rbl([$long_yahoo], 'sc.surbl.org', '127.0.0.2'), 'test redirect is bad');


