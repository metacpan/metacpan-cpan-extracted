#!perl

# program to test HTTP::ProxyAutoConfig
use strict;
use warnings;
use Sys::Hostname;
use Test::More tests => 18;
use LWP::UserAgent;

# test 1 is use_ok
BEGIN {use_ok ('HTTP::ProxyAutoConfig')}

my $pos = tell DATA;
my ($url, $exp_proxy, $got_proxy);

# generate the calling object
my $pac = HTTP::ProxyAutoConfig->new('t/example.pac');

# test 2: check it
isa_ok ($pac, 'HTTP::ProxyAutoConfig');

# tests 3-10 (4 data lines): test the correspondences below
my $line = 0;
while (<DATA>) {
  $line++;
  if (ok(/^\s*(.+?)\s+(.+?)\s*$/, "proper format of __DATA__ line $line")) {
    ($url, $exp_proxy) = ($1, $2);
    $got_proxy = $pac->FindProxy($url);
    is ($got_proxy, $exp_proxy, "check returned proxy, __DATA__ line $line");
} }
seek DATA, $pos, 0;
undef $pac;

# try getting .pac file from internet
my $ua = LWP::UserAgent->new(timeout => 30);
my ($pac_url, $pac_urlOK);

for ($HTTP::ProxyAutoConfig::VERSION, '0.2') {
  # put a previous version here -------^, in case we haven't uploaded this $VERSION yet
  $pac_url = "http://cpansearch.perl.org/src/MACKENNA/HTTP-ProxyAutoConfig-$_/t/example.pac";
  my $resp = $ua->head($pac_url);
  if ($resp->is_success) {
    $pac_urlOK = 1;
    last;
} }
undef $ua;

SKIP: {
  skip "Can't find .pac file on CPAN", 8 unless $pac_urlOK;
  $pac = HTTP::ProxyAutoConfig->new($pac_url);
  # tests 11-18 (4 data lines): test the correspondences below
  my $line = 0;
  while (<DATA>) {
    $line++;
    if (ok(/^\s*(.+?)\s+(.+?)\s*$/, "proper format of __DATA__ line $line")) {
      ($url, $exp_proxy) = ($1, $2);
      $got_proxy = $pac->FindProxy($url);
      is ($got_proxy, $exp_proxy, "check returned proxy, __DATA__ line $line");
  } }
}
__DATA__
http://frodo.example.com/ohno.html      DIRECT
http://10.0.7.247/MLKJJHG.jpg           PROXY www.google.com:80
http://10.0.8.0/index.html              PROXY www.yahoo.com:80
http://www.animalhead.com/contact.html  PROXY www.yahoo.com:80
