#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("deferred_refs");
use Test; BEGIN { plan tests => 8 };

# ---------------------------------------------------------------------------

sub runcb {
  while (<IN>) {
    s/REQ\d+/ $found{$&}++; ""; /ge;
  }
}

ok (wmrun ("-F -f data/deferred_refs.wmk", \&runcb));
ok ($found{'REQ1'});
ok ($found{'REQ2'});
ok ($found{'REQ3'});

# from cache
ok (wmrun ("-f data/deferred_refs.wmk", \&runcb));
ok ($found{'REQ1'});
ok ($found{'REQ2'});
ok ($found{'REQ3'});


