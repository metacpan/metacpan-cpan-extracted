#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("breadcrumbs");
use Test; BEGIN { plan tests => 11 };

# ---------------------------------------------------------------------------

%patterns = (

q{ [ <a href="../log/breadcrumbs.html">site map</a> / &nbsp; -- &nbsp; <a
href="../log/breadcrumbs.html">Map</a> <hr /> <li> <a
href="../log/breadcrumbs.html">site map</a>: Map of the site<br /> <ul> <li> <a
href="../log/breadcrumbs_story_1.html">Story 1, blah blah</a>: Story 1, just
another story.<br /> <ul> <li> <a href="../log/breadcrumbs_story_2.html">Story
2, blah blah</a>: Story 2, just another story.<br /> <ul> <li> <a
href="../log/breadcrumbs_story_3.html">Hot! story 3, etc etc.</a>: Story 3, the
highest-scored story.<br /> <ul> <li> <a
href="../log/breadcrumbs_story_5.html">Story 5, zzz blah blah</a>: Story 5,
nothing much here.<br /> <ul> <li> <a
href="../log/breadcrumbs_story_6.html">Story 6, blah blah</a>: Story 6, just
another story.<br /> },	'mainpage',

q{ [ <a href="../log/breadcrumbs.html">site map</a> /<a
href="../log/breadcrumbs_story_1.html">Story 1, blah blah</a> /<a
href="../log/breadcrumbs_story_2.html">Story 2, blah blah</a> /<a
href="../log/breadcrumbs_story_3.html">Hot! story 3, etc etc.</a> /<a
href="../log/breadcrumbs_story_5.html">Story 5, zzz blah blah</a> /<a
href="../log/breadcrumbs_story_6.html">Story 6, blah blah</a> ] &nbsp; --
&nbsp; <a href="../log/breadcrumbs.html">Map</a> <hr /> <p>

This is story 6.}, 'story6',


q{[ <a href="../log/breadcrumbs.html">site map</a> /<a
href="../log/breadcrumbs_story_1.html">Story 1, blah blah</a> /<a
href="../log/breadcrumbs_story_2.html">Story 2, blah blah</a> /<a
href="../log/breadcrumbs_story_3.html">Hot! story 3, etc etc.</a> ] &nbsp; --
&nbsp; <a href="../log/breadcrumbs.html">Map</a> <hr /> <p>

Breaking news! this is story 3.}, 'story3',


q{ [ <a href="../log/breadcrumbs.html">site map</a> /<a
href="../log/breadcrumbs_story_1.html">Story 1, blah blah</a> ] &nbsp; --
&nbsp; <a href="../log/breadcrumbs.html">Map</a> <hr /> <p>

This is story 1.}, 'story1',

q{ [ <a href="../log/breadcrumbs.html">site map</a> /<a
href="../log/breadcrumbs_story_1.html">Story 1, blah blah</a> /<a
href="../log/breadcrumbs_story_2.html">Story 2, blah blah</a> /<a
href="../log/breadcrumbs_story_4.html">Story 4, zzzzzzz</a> ] &nbsp; -- &nbsp;
<a href="../log/breadcrumbs.html">Map</a> <hr /> <p>

This is story 4. It's astoundingly boring, which is why it's down here.},
'story4',

);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_story_1.html", \&patterns_run_cb);
checkfile ($testname."_story_2.html", \&patterns_run_cb);
checkfile ($testname."_story_3.html", \&patterns_run_cb);
checkfile ($testname."_story_4.html", \&patterns_run_cb);
checkfile ($testname."_story_5.html", \&patterns_run_cb);
checkfile ($testname."_story_6.html", \&patterns_run_cb);
# etc.
ok_all_patterns();

