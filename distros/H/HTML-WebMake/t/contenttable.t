#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("contenttable");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

q{scoop websites onto your PalmPilot<br />

Download<br />

CVS Access<br />

Reviews<br />

Similar Projects<br />}, 'titles'

);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();

