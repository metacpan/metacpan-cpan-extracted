#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("paramrefs");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

$file = q{
  <webmake>
  <content name="foo">foo!</content>
  <template name="template">
  	Expanding :::${${contentname}}:::
  </template>

  <out file="log/paramrefs.html">
  	${template: contentname="foo"}
  </out>
  </webmake>
};

%patterns = (

q{Expanding :::foo!:::}, 'gotit',

);

# ---------------------------------------------------------------------------

wmfile ($file);
ok (wmrun ("-F -f log/test.wmk", \&patterns_run_cb));
ok_all_patterns();

