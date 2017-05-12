#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("contentsfind3");
use Test; BEGIN { plan tests => 7 };

# ---------------------------------------------------------------------------

%patterns = (

  q{This is foo.}, 'foo',

  q{This is bar.}, 'bar',

);

%anti_patterns = (

  q{This is baz.}, 'baz',

  q{I am floop}, 'floop',

);

print "(A 'no value defined for metadata' error is expected here)\n";
ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();
