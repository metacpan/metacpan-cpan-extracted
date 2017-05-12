#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("metatable");
use Test; BEGIN { plan tests => 7 };

# ---------------------------------------------------------------------------

%patterns = (
  q{Name: foo
  Title: This is Foo
  Section: sec1
  Score: 50},
  'foo',

  q{Name: dir1/bar
  Title: This is Bar
  Section: sec2
  Score: 30},
  'bar',

  q{Name: dir2/dir2a/baz
  Title: This is Baz
  Section: sec1
  Score: 20},
  'baz',

);

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();
