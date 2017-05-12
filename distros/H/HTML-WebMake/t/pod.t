#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("pod");
use Test; BEGIN { plan tests => 10 };

# ---------------------------------------------------------------------------

%patterns = (
  q{ <ul> <li> <a href=},
  'pod_header_list',

  q{ <h1><a name="name">NAME</a></h1> <p> Blah foo etc.},
  'pod_name',

  q{DESCRIPTION</a></h1>},
  'pod_description',

  q{ <h1><a name=},
  'bar_found',
);

%anti_patterns = (
  q{ <ul> <li> <a href="#bar_name">BAR_NAME</a> <li>
  <a href="#bar_description">BAR_DESCRIPTION</a> </ul>},
  'anti_bar_header_list',
);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();

# clean up some leftover tmp files
unlink ("pod2html-dircache");
unlink ("pod2html-itemcache");

