#!perl

# program to test HTTP::ProxyPAC, adapted from HTTP::ProxyAutoConfig

use strict;
use warnings;

my @interps;
BEGIN {
  eval "require JavaScript";
  if (!$@) {push @interps, 'javascript'}
  eval "require JE";
  if (!$@) {push @interps, 'je'}  
}
use Test::More tests => 18*@interps;
use HTTP::ProxyPAC;

if (!@interps) {BAIL_OUT("Neither the JavaScript nor JE module is installed")}

my $pos = tell DATA;

# perform the tests for the installed interpreter(s) and both libraries
for my $interp (@interps) {
  for my $lib ('javascript', 'perl') {
  
    diag("testing with $interp interpreter and $lib PAC-library");

    # generate the calling object
    my $pac = HTTP::ProxyPAC->new('t/example.pac', 'interp' => $interp, 'lib' => $lib);
    
    # 2 or 11 check it
    isa_ok ($pac, 'HTTP::ProxyPAC');
    
    # tests 3-10, 12-19, maybe 21-28, 30-37 (4 data lines): test the correspondences below
    my $lineNo = 0;
    while (<DATA>)  {
      chomp;
      $lineNo++;
      if (ok(/^\s*(.+?)\s+(.+?)\s*$/, "is DATA line $lineNo in proper format?")) {
        my ($url, $exp_proxy) = ($1, $2);
        my $res = $pac->find_proxy($url);
        if ($exp_proxy eq 'DIRECT') {
          ok ($res->direct, "response for $url should be DIRECT");
        } else {
          is ($res->proxy && $res->proxy->host_port, $exp_proxy, 
              "returned proxy for $url should be $exp_proxy");
    } } }
    seek DATA, $pos, 0;
} }
__DATA__
http://frodo.example.com/ohno.html      DIRECT
http://10.0.7.247/MLKJJHG.jpg           www.google.com:80
http://10.0.8.0/index.html              www.yahoo.com:80
http://www.animalhead.com/contact.html  www.yahoo.com:80
