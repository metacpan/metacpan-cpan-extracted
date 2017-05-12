#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("navlinks");
use Test; BEGIN { plan tests => 17 };

# ---------------------------------------------------------------------------

%patterns = (

q{ <a href="../log/navlinks_map.html">Site Map</a> <hr /> | | <a
href="../log/navlinks_story_3.html">Next</a> <hr /> <ul> <li> <a
href="../log/navlinks_story_3.html">Hot! story 3, etc etc.</a><br /> <p> Story
3, the highest-scored story.  </p> </li> <li> <a
href="../log/navlinks_story_1.html">Story 1, blah blah</a><br /> <p> Story 1,
just another story.  </p> </li> <li> <a
href="../log/navlinks_story_2.html">Story 2, blah blah</a><br /> <p> Story 2,
just another story.}, 'index_top',


q{ <a href="../log/navlinks_map.html">Site Map</a><hr /> <a
href="../log/navlinks_story_3.html">Previous</a> | <a
href="../log/navlinks.html">Up</a> | <a
href="../log/navlinks_story_2.html">Next</a><hr /> <p> This is story
1.

</p>
<hr />
}, 'story1',


q{ <a href="../log/navlinks_map.html">Site Map</a> <hr /> <a
href="../log/navlinks_story_1.html">Previous</a> | <a
href="../log/navlinks.html">Up</a> | <a
href="../data/contentsfind.data/dir1/bar.txt">Next</a> <hr /> <p> This
is story 2.

</p>
}, 'story2',


q{ <a href="../log/navlinks_map.html">Site Map</a> <hr /> <a
href="../log/navlinks.html">Previous</a> | <a
href="../log/navlinks.html">Up</a> | <a
href="../log/navlinks_story_1.html">Next</a> <hr /> <p> Breaking news!  this is
story 3. </p> <hr /> }, 'story3',

q{<a href="../log/navlinks.html">Index</a> | <a
href="../log/navlinks_map.html">Site Map</a><hr /> <a
href="../log/navlinks_map.html">Previous</a> | <a
href="../log/navlinks.html">Up</a> | <hr /> <p> This is story 4},
'story4',

q{ <h1>Navlinks Test</h1> <hr /> <a href="../log/navlinks.html">Index</a> | <a
href="../log/navlinks_map.html">Site Map</a> <hr /> <a
href="../log/navlinks_story_6.html">Previous</a> | <a
href="../log/navlinks.html">Up</a> | <a
href="../data/contentsfind.data/dir2/dir2a/baz.txt">Next</a> <hr />}, 'story5',

q{ <a href="../log/navlinks_map.html">Site Map</a> <hr /> <a
href="../data/contentsfind.data/dir1/bar.txt">Previous</a> | <a
href="../log/navlinks.html">Up</a> | <a
href="../log/navlinks_story_5.html">Next</a> <hr /> <p> This is story
6.  }, 'story6',

q{ <a href="../log/navlinks_map.html">Site Map</a> <hr /> <a
href="../data/contentsfind.data/foo.txt">Previous</a> | <a
href="../log/navlinks.html">Up</a> | <a
href="../log/navlinks_story_4.html">Next</a> <hr /> <li> <p> <a
href="../log/navlinks.html">WebMake Sample: a news site</a>: some old news
site<br /> <em>[score: 50, name: index_chunk, is_node: 1]</em> <ul> <li> <p> <a
href="../log/navlinks_story_3.html">Hot! story 3, etc etc.</a>: Story 3, the
highest-scored story.<br /> <em>[score: 10, name: story_3.txt, is_node: 0]</em>
</p> </li> <li> <p> <a href="../log/navlinks_story_1.html">Story 1, blah
blah</a>: Story 1, just another story.<br /> <em>[score: 20, name: story_1.txt,
is_node: 0]</em> </p> }, 'sitemap',

);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_map.html", \&patterns_run_cb);
checkfile ($testname."_story_1.html", \&patterns_run_cb);
checkfile ($testname."_story_2.html", \&patterns_run_cb);
checkfile ($testname."_story_3.html", \&patterns_run_cb);
checkfile ($testname."_story_4.html", \&patterns_run_cb);
checkfile ($testname."_story_5.html", \&patterns_run_cb);
checkfile ($testname."_story_6.html", \&patterns_run_cb);
# etc.
ok_all_patterns();

