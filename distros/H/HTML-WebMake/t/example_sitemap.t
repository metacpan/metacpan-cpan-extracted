#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("example_sitemap");
use Test; BEGIN { plan tests => 7 };

# ---------------------------------------------------------------------------

%patterns = (



  q{This is story 1.},
  'story_1_body',


  q{Breaking news! this is story 3.},
  'story_3_body',

 q{<a href="../log/example_sitemap_story_3.html">Hot! story 3, etc etc.</a><br />
 <p> Story 3, the highest-scored story.  </p> </li> <li>
 <a href="../log/example_sitemap_story_1.html">Story 1, blah blah</a><br />
 <p> Story 1, just another story.  </p> </li> <li>
 <a href="../log/example_sitemap_story_2.html">Story 2, blah blah</a><br />
 <p> Story 2, just another story.  </p>},
  'index_ordering',


);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_map.html", \&patterns_run_cb);
checkfile ($testname."_fullmap.html", \&patterns_run_cb);
checkfile ($testname."_story_1.html", \&patterns_run_cb);
checkfile ($testname."_story_3.html", \&patterns_run_cb);
# etc.
ok_all_patterns();

