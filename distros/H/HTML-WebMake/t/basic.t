#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("basic");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

  q{ Foo! }, 'foo',

);

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();
