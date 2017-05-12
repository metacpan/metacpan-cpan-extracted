#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("safetag");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

$file = q{
  <webmake>
  <use plugin="safe_tag" />

  <content name="foo" format="text/et">
  <table><tr><td>
The default setting is ##~/.webmake/%F##.

Example
=======

<safe>
  <cache file="../webmake.cache" />
</safe>

Got it?
</td></tr></table>
  </content>

  <out file="log/safetag.html">${foo}</out>
  </webmake>
};

%patterns = (

q{ <!--etsafe--> <pre> &lt;cache file="../webmake.cache" /&gt; </pre><!--/etsafe-->
}, 'etsafe'

);

# ---------------------------------------------------------------------------

wmfile ($file);
ok (wmrun ("-F -f log/test.wmk", \&patterns_run_cb));
ok_all_patterns();

