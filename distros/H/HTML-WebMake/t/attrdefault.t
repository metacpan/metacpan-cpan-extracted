#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("attrdefault");
use Test; BEGIN { plan tests => 5 };

# ---------------------------------------------------------------------------

$file = q{
  <webmake>
  <attrdefault name="format" value="text/html" />

  <attrdefault name="format" value="text/et">
  <content name="foo">**Test.**</content>
  </attrdefault>

  <content name="bar">**Test.**</content>

  <out file="log/attrdefault.html">${foo}${bar}</out>
  </webmake>
};

%patterns = (

q{<strong>Test.</strong>}, 'ettext',

q{**Test.**}, 'html',

);

# ---------------------------------------------------------------------------

wmfile ($file);
ok (wmrun ("-F -f log/test.wmk", \&patterns_run_cb));
ok_all_patterns();

