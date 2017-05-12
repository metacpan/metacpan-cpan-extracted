#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("sitemap_with_metatable");
use Test; BEGIN { plan tests => 5 };

# ---------------------------------------------------------------------------

%patterns = (


  q{<li> <p> <a href="../log/sitemap_with_metatable_story_2.html">Story
 2, blah blah</a>: Story 2, just another story.<br /> <em>[score:
 20, name: story_2.txt, is_node: 1]</em> <ul> <li> <p>
 <a href="../data/contentsfind.data/dir1/bar.txt">This
 is Bar</a>: Abstract for bar<br />
 <em>[score: 30, name: dir1/bar.txt, is_node: 0]</em> </p> </li> </ul>
 </p> </li>},
  'small_map_bar_under_story_2',


  q{
   
 <a href="../log/sitemap_with_metatable_story_5.html">Story 5, zzz blah blah</a>: Story 5, nothing much here.<br />
 <em>[score: 21, name: story_5.txt, is_node: 0]</em>
</p>
  
</li>
<li>
 <p>
 <a href="../data/contentsfind.data/foo.txt">This is Foo</a>: Abstract for foo<br />
 <em>[score: 45, name: foo.txt, is_node: 0]</em> 
</p>
                                                                                  </li> 
<li>
 <p>
 <a href="../log/sitemap_with_metatable_map.html">(Untitled)</a>: <br />
 <em>[score: 50, name: mainsitemap, is_node: 0]</em>
</p>
</li>
<li>
 <p>
 <a href="../log/sitemap_with_metatable_fullmap.html">(Untitled)</a>: <br />
 <em>[score: 50, name: fullsitemap, is_node: 0]</em>
</p>

</li>
<li>
 <p>
 <a href="../log/sitemap_with_metatable_story_4.html">Story 4, zzzzzzz 
    
  },
  'small_map_foo_between_5_and_4',

);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_map.html", \&patterns_run_cb);
# etc.
ok_all_patterns();

