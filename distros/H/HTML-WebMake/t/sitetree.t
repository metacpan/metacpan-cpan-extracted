#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("sitetree");
use Test; BEGIN { plan tests => 17 };

# ---------------------------------------------------------------------------

%patterns = (

q{
 <h1>WebMake Sitemap Demo</h1> <hr />
 <li>
 <strong>&gt;</strong> <a href="../log/sitetree.html">WebMake Sample: a news site<
/a>: some old news site<br />
 
</li>}, 'firstpage',






 q{<strong>.</strong> <a href="../log/sitetree_story_5.html">Story 5, zzz blah blah<
/a>: Story 5, nothing much here.<br />
 
</li>
<li>
 <strong>&gt;</strong> <a href="../log/sitetree_map.html">WebMake Sample: site map
</a>: Map of the site<br />
 
</li>
<li>
 <strong>.</strong> <a href="../log/sitetree_story_4.html">Story 4, zzzzzzz</a>: S
tory 4, incredibly boring.<br />}, 'bot_map',




q{</li>
<li>
 <strong>&gt;</strong> <a href="../log/sitetree_story_1.html">Story 1, blah blah</
a>: Story 1, just another story.<br />
 
</li>
<li>
 <strong>.</strong> <a href="../log/sitetree_story_2.html">Story 2, blah blah</a>:
 Story 2, just another story.<br />}, 'story1',

 



q{</li>
<li>
 <strong>&gt;</strong> <a href="../log/sitetree_story_2.html">Story 2, blah blah</
a>: Story 2, just another story.<br />
 
</li>
<li>
 <strong>.</strong> <a href="../log/sitetree_story_6.html">Story 6, blah blah</a>:
 Story 6, just another story.<br />}, 'story2',






 q{<strong>-</strong> <a href="../log/sitetree.html">WebMake Sample: a news site</a>
: some old news site<br />
 <ul>
<li>
 <strong>&gt;</strong> <a href="../log/sitetree_story_3.html">Hot! story 3, etc et
c.</a>: Story 3, the highest-scored story.<br />
 
</li>
<li>
 <strong>.</strong> <a href="../log/sitetree_story_1.html">Story 1, blah blah</a>:
 Story 1, just another story.<br />}, 'story3',

 


 
q{</li>
<li>
 <strong>&gt;</strong> <a href="../log/sitetree_story_4.html">Story 4, zzzzzzz</a>
: Story 4, incredibly boring.<br />
 
</li>
</ul>
 
</li>}, 'story4',




 q{<strong>.</strong> <a href="../log/sitetree_story_6.html">Story 6, blah blah</a>:
 Story 6, just another story.<br />
 
</li>
<li>
 <strong>&gt;</strong> <a href="../log/sitetree_story_5.html">Story 5, zzz blah bl
ah</a>: Story 5, nothing much here.<br />
 
</li>
<li>
 <strong>.</strong> <a href="../log/sitetree_map.html">WebMake Sample: site map</a
>: Map of the site<br />
}, 'story5',



q{</li>
<li>
 <strong>&gt;</strong> <a href="../log/sitetree_story_6.html">Story 6, blah blah</
a>: Story 6, just another story.<br />
 
</li>
<li>
 <strong>.</strong> <a href="../log/sitetree_story_5.html">Story 5, zzz blah blah<
/a>: Story 5, nothing much here.<br />
}, 'story6',





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

