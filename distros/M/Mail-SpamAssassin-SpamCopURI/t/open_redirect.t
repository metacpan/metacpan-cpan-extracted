#!perl -w

use Test::More tests => 5;
use strict;
use Mail::SpamAssassin::SpamCopURI;
use Mail::SpamAssassin::PerMsgStatus;;
use Mail::SpamAssassin::Conf;;

my $conf = Mail::SpamAssassin::Conf->new;
my $msg = Mail::SpamAssassin::PerMsgStatus->new();
$msg->{main} = Mail::SpamAssassin->new;
$msg->{conf} = $conf;

$conf->add_to_addrlist ('open_redirect_list_spamcop_uri', 'rd.yahoo.com', 'snipurl.com');

my $redirect_url = 'http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar';

my $dead_end = 'http://rd.yahoo.com/swage/*foo';

my $quint_redirect_url = 'http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar';


# snipurl to http://surbl-org-permanent-test-point.com/foo/bar
my $snip_url = "http://snipurl.com/67oj";



SKIP: {
  #eval { require LWP::UserAgent;
  #      my $ua = LWP::UserAgent->new;
  #      $ua->timeout(10);
  #      $ua->env_proxy;
  #      my $response = $ua->get('http://www.surbl.org/');
  #      $response->is_success or die "request failed: " . $response->as_string;
  #};
  #skip "LWP::UserAgent not installed or can't fetch", 5 if $@;

  skip "Need reliable open redirect to test against - rd.yahoo.com is closed", 5 if 1;



  my $sc = Mail::SpamAssassin::SpamCopURI->new($msg);  

  my @urls = $sc->_extract_redirect_urls($redirect_url);

  ok(eq_set(\@urls, ['http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar', 
		     'http://surbl-org-permanent-test-point.com/foo/bar']), 
		     "all urls equals what we expected for: $redirect_url");

  # doing twice to get cache data
  @urls = $sc->_extract_redirect_urls($redirect_url);

  ok(eq_set(\@urls, ['http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar', 
		     'http://surbl-org-permanent-test-point.com/foo/bar']), 
		     "all urls equals what we expected for: $redirect_url");


  @urls = $sc->_extract_redirect_urls($quint_redirect_url);

  # this should hit the redirect limit
  ok(eq_set(\@urls, ['http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar',
                     'http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar',
                     'http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar',
		     'http://rd.yahoo.com/swage/*http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar',
		     'http://rd.yahoo.com/swage/*http://surbl-org-permanent-test-point.com/foo/bar']), 
		     "all urls equals what we expected for: $quint_redirect_url");


  @urls = $sc->_extract_redirect_urls($dead_end);

  # this should hit the dead end 
  ok(eq_set(\@urls, [$dead_end]), 'only one url found for dead end');
  

  ok($msg->check_spamcop_uri_rbl([$snip_url], 'sc.surbl.org', '127.0.0.2') == 0, 
           'test snip_url is good pre-config');

  $msg->{conf}->{spamcop_uri_resolve_open_redirects} = 1;

  # ok($msg->check_spamcop_uri_rbl([$snip_url], 'sc.surbl.org', '127.0.0.2'), 'test snip_url is bad post-config');


};

