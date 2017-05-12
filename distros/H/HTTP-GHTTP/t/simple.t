# $Id: simple.t,v 1.4 2001/01/18 17:43:10 matt Exp $

use Test;
use HTTP::GHTTP;
use strict;
BEGIN { plan tests => 3 }
ok(1);

{
  my $r = HTTP::GHTTP->new();
  ok($r);
  ok($r->set_uri("http://axkit.org/"));
}
