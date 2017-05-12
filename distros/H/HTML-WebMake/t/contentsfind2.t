#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("contentsfind2");
use Test; BEGIN { plan tests => 8 };

# ---------------------------------------------------------------------------

%patterns = (

  q{This is foo.}, 'foo',

  q{This is bar.}, 'bar',

  q{This is baz.}, 'baz',

);

%anti_patterns = (

  q{I am floop}, 'floop',

);

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();
