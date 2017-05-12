#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("deeplinks");
use Test; BEGIN { plan tests => 7 };

# ---------------------------------------------------------------------------

$file = q{
  <webmake>
  <content name="foo" format=text/et> <a href="$(bar)">foo</a>
  </content>
  <content name="bar" format=text/et> bar [$(baz)]
  </content>
  <content name="baz" format=text/html> <a href=$(foo)>baz</a>
  </content>

  <out file="log/deeplinks.html" name=foo>${foo}</out>
  <out file="log/deeplinks/dir1/bar.html" name=bar>${bar}</out>
  <out file="log/deeplinks/dir2/baz.html" name=baz>${baz}</out>
  </webmake>
};

%patterns = (

q{<a href="../log/deeplinks/dir1/bar.html">foo</a> }, 'foo',

q{<a href="../../../log/deeplinks/dir2/baz.html">bar</a> }, 'bar',

q{<a href="../../../log/deeplinks.html">baz</a>}, 'baz',

);

# ---------------------------------------------------------------------------

wmfile ($file);
ok (wmrun ("-F -f log/test.wmk", \&patterns_run_cb));
checkfile ("deeplinks/dir1/bar.html", \&patterns_run_cb);
checkfile ("deeplinks/dir2/baz.html", \&patterns_run_cb);
ok_all_patterns();

