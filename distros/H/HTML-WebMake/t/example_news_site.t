#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("example_news_site");
use Test; BEGIN { plan tests => 11 };

# ---------------------------------------------------------------------------

%patterns = (
 q{<a href="../log/example_news_site_story_2.html">Story 2, blah blah</a><br />},
  'links',

 q{<li> <a
 href="../log/example_news_site_story_3.html">Hot! story 3, etc etc.</a><br /> 
 <p> Story 3, the highest-scored story.  </p> </li> <li>
 <a href="../log/example_news_site_story_1.html">Story 1, blah blah</a><br />
 <p> Story 1, just another story.  </p> </li> <li>
 <a href="../log/example_news_site_story_2.html">Story 2, blah blah</a><br />
 <p> Story 2, just another story.  </p>},
  'correct_sorting_top',

  q{<li>
 <a href="../log/example_news_site_story_5.html">Story 5,
 zzz blah blah</a><br /> <p> Story 5, nothing much here.  </p> </li> <li>
 <a href="../log/example_news_site_story_4.html">Story 4, zzzzzzz</a><br />
 <p> Story 4, incredibly boring.  </p>},
  'correct_sorting_bottom',

  q{<html> <head> <title> Story 1, blah blah </title> </head>},
  'story_1_title',

  q{Breaking news! this is story 3.},
  'story_3_body',


);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_story_1.html", \&patterns_run_cb);
checkfile ($testname."_story_3.html", \&patterns_run_cb);
# etc.
ok_all_patterns();

