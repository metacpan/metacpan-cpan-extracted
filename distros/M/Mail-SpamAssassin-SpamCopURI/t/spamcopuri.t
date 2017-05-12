#!perl -w

use Test::More tests => 14;
use Mail::SpamAssassin::SpamCopURI;
use Mail::SpamAssassin::PerMsgStatus;



eval {
  my $sc = Mail::SpamAssassin::SpamCopURI->new();
};

ok($@ =~ /must supply a PerMsgStatus/, 
   'constructor dies with error when missing PerMsgStatus');

my $msg = Mail::SpamAssassin::PerMsgStatus->new;
my $sc = Mail::SpamAssassin::SpamCopURI->new($msg);

my $sc2 = $sc->new($msg);
ok(ref($sc2) eq 'Mail::SpamAssassin::SpamCopURI', 
  'constructor works with blessed reference');

# just for Devel::Cover kicks
eval {$sc = Mail::SpamAssassin::SpamCopURI::new()};
ok($@ =~ /must supply a PerMsgStatus/, 
   'constructor dies with error when missing self');

my $malformed_url = 'http://www.yahoo.com)foo';

my $sc_url = $sc->_spamcop_uri($malformed_url);
ok($sc_url->{host} eq 'www.yahoo.com', 'trailing paren is stripped off of the end');

$sc_url = $sc->_spamcop_uri('http://');

ok($sc_url->{as_string} eq 'http://');

$sc_url = $sc->_spamcop_uri('');

ok(!defined $sc_url, 'sc not defined when empty string passed in');

$sc_url = $sc->_spamcop_uri('http://www=2eseo500=2ecom');

ok($sc_url->{host} eq 'www.seo500.com', '=2e was cleaned up');

my @list = qw( a a b b c c );

my @uniq = Mail::SpamAssassin::SpamCopURI::uniq(@list);

ok(eq_set(\@uniq, [qw(a b c)]), 'uniq thing works');

$sc_url = $sc->_spamcop_uri('http://211.238.180.181/manual/mod/.help/hide/index2.htm');

ok($sc_url->{host} eq '211.238.180.181', 'ip address passes cleanly');

$sc_url = $sc->_spamcop_uri('http://.');

ok($sc_url->{host} eq '', '. host does not cause error');

$sc_url = $sc->_spamcop_uri('http://0xd5.172.31.16/bigtitpatrol/index.html');

ok($sc_url->{host} eq '213.172.31.16', 'host was de-hexed');

$sc_url = $sc->_spamcop_uri('http://.spammy-site.org');

ok($sc_url->{host} eq 'spammy-site.org', 'first dot removed');

$sc_url = $sc->_spamcop_uri('http://1110325108/bigtitpatrol/index.html');

ok($sc_url->{host} eq '66.46.55.116', 'host was de-base10');

$sc_url = $sc->_spamcop_uri('http://%38%31%2E%32%30%38%2E%33%31%2E%31%37%33:%34%39%30%33/%63%69%74/%69%6E%64%65%78%2E%68%74%6D');

# port was tacked on to the host as: 81.208.31.173:4903
ok($sc_url->{host} eq '81.208.31.173', 'host was de-hexed properly and port stripped off');


