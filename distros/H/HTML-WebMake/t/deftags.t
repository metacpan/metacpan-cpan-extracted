#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("deftags");
use Test; BEGIN { plan tests => 5 };

# ---------------------------------------------------------------------------

%patterns = (
  '<b>bar: name=glorp</b>',
  'bar_tag',

  '<b>baz: name=foop value=yep</b>',
  'baz_tag',
);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();

