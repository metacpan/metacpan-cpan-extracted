#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("navlinks_with_pod");
use Test; BEGIN { plan tests => 13 };

# ---------------------------------------------------------------------------

%patterns = (

q{ <a href="../log/navlinks_with_pod_story_3.html">Previous</a> | <a
href="../log/navlinks_with_pod.html">Up</a> | <a
href="../log/navlinks_with_pod_story_2.html">Next</a> <hr /> <p> This
is story 1.  }, 'story1_links',

q{ <a href="../log/navlinks_with_pod_map.html">Site Map</a> <hr /> | | <a
href="../log/navlinks_with_pod_story_3.html">Next</a> <hr /> <ul> <li> <a
href="../log/navlinks_with_pod_story_3.html">Hot! story 3, etc etc.</a><br />
<p> Story 3, the highest-scored story.  }, 'front',



 q{<a href="../log/navlinks_with_pod_map.html">Site Map</a> <hr /> <a
 href="../data/contentsfind.data/foo.txt">Previous</a> | <a
 href="../log/navlinks_with_pod.html">Up</a> | <a
 href="../log/navlinks_with_pod_pod2.html">Next</a> <hr /> <li> <p> <a
 href="../log/navlinks_with_pod.html">WebMake Sample: a news site</a>: some old
 news site<br /> }, 'map1',


 q{<a href="../log/navlinks_with_pod.html">Index</a> | <a
 href="../log/navlinks_with_pod_map.html">Site Map</a> <hr /> <a
 href="../log/navlinks_with_pod_pod2.html">Previous</a> | <a
 href="../log/navlinks_with_pod.html">Up</a> | <a
 href="../log/navlinks_with_pod_story_ 4.html">Next</a> <hr /> },
 'pod1',

  q{ <a href="../log/navlinks_with_pod.html">Index</a> | <a
  href="../log/navlinks_with_pod_map.html">Site Map</a> <hr /> <a
  href="../log/navlinks_with_pod_map.html">Previous</a> | <a
  href="../log/navlinks_with_pod.html">Up</a> | <a
  href="../log/navlinks_with_pod_pod1.html">Next</a> <hr /> }, 'pod2',


 q{<h1>Navlinks With PODs</h1> <hr /> <a
 href="../log/navlinks_with_pod.html">Index</a> | <a
 href="../log/navlinks_with_pod_map.html">Site Map</a> <hr /> <a
 href="../data/contentsfind.data/dir1/bar.txt">Previous</a> | <a
 href="../log/navlinks_with_pod.html">Up</a> | <a
 href="../log/navlinks_with_pod_story_5.html">Next</a> <hr /> <p>
 }, 'story6',

);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_map.html", \&patterns_run_cb);
checkfile ($testname."_pod1.html", \&patterns_run_cb);
checkfile ($testname."_pod2.html", \&patterns_run_cb);
checkfile ($testname."_story_1.html", \&patterns_run_cb);
checkfile ($testname."_story_2.html", \&patterns_run_cb);
checkfile ($testname."_story_3.html", \&patterns_run_cb);
checkfile ($testname."_story_4.html", \&patterns_run_cb);
checkfile ($testname."_story_5.html", \&patterns_run_cb);
checkfile ($testname."_story_6.html", \&patterns_run_cb);
# etc.
ok_all_patterns();

