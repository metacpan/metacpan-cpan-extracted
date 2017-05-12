#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("imgsize");
use Test; BEGIN { plan tests => 7 };

# ---------------------------------------------------------------------------

$file = q{
  <webmake>

  <content name="foo">**Test foo.** ${logo}</content>
  <content name="bar">**Test bar.** ${logo}</content>
  <content name="logo">
  <img src="$(TOP/)data/test.gif" ${IMGSIZE} alt="logo" border="0">
  </content>

  <out file="log/imgsize.html">${foo}</out>
  <out file="log/foo/bar.html">${bar}</out>
  </webmake>
};

%patterns = (

q{**Test foo.**}, 'html',

q{**Test foo.** <img src="../data/test.gif" alt="logo" border="0" width="6"
height="55" />}, 'level1',

q{**Test bar.** <img src="../../data/test.gif" alt="logo" border="0" width="6"
height="55" />}, 'level2',

);

# ---------------------------------------------------------------------------

wmfile ($file);
ok (wmrun ("-F -f log/test.wmk", \&patterns_run_cb));
checkfile ("foo/bar.html", \&patterns_run_cb);
ok_all_patterns();


