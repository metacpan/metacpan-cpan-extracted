#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("metadefault");
use Test; BEGIN { plan tests => 7 };

# ---------------------------------------------------------------------------

%patterns = (

q{
<li>
 <a href="../log/metadefault_story_3.html">Hot! story 3, etc etc.</a><br />
 <p>
Story 3, the highest-scored story.
</p>
 
</li>
<li>
 <a href="../log/metadefault_story_1.html">Story 1, blah blah</a><br />
 <p>
Story 1, just another story.
</p>
 
</li>
<li>
 <a href="../log/metadefault_story_2.html">Story 2, blah blah</a><br />
 <p>
Story 2, just another story.
</p>
 
</li>
},	'top_index',

q{
 <a href="../log/metadefault.html">WebMake Sample: a news site</a>: some old news 
site<br />
 <em>[score: 50, name: index_chunk, is_node: 1]</em> <ul>
 <li>
 <p>
 <a href="../log/metadefault_story_3.html">Hot! story 3, etc etc.</a>: Story 3, th
e highest-scored story.<br />
 <em>[score: 10, name: story_3.txt, is_node: 0]</em> 
</p>
 
</li>
<li>
 <p>
 <a href="../log/metadefault_story_1.html">Story 1, blah blah</a>: Story 1, just a
nother story.<br />
 <em>[score: 20, name: story_1.txt, is_node: 0]</em> 
</p>
 
</li>
<li>
 <p>
 <a href="../log/metadefault_story_2.html">Story 2, blah blah</a>: Story 2, just a
nother story.<br />
}, 'top_map',

q{
 <a href="../log/metadefault_story_2.html">Story 2, blah blah</a>: Story 2, just a
nother story.<br />
 <em>[score: 20, name: story_2.txt, is_node: 0]</em> 
</p>
 
</li>
<li>
 <p>
 <a href="../log/metadefault_map.html">WebMake Sample: a news site</a>: some old n
ews site<br />
 <em>[score: 50, name: mainsitemap, is_node: 0]</em> 
</p>
 
</li>
<li>
 <p>
 <a href="../log/metadefault_fullmap.html">WebMake Sample: full site map</a>: Full
 map of the site<br />
 <em>[score: 50, name: fullsitemap, is_node: 0]</em> 
</p>
 
</li>

}, 'bot_map',



);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_map.html", \&patterns_run_cb);
checkfile ($testname."_story_1.html", \&patterns_run_cb);
checkfile ($testname."_story_3.html", \&patterns_run_cb);
# etc.
ok_all_patterns();

