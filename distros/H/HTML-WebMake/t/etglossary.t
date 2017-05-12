#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("etglossary");
use Test; BEGIN { plan tests => 17 };

# ---------------------------------------------------------------------------

%patterns = (

  q{Glossary test 1: try this link to
  <a href="http://slashdot.org/">slashdot</a>},
  'link_defn',

  q{Glossary test 2: refer to that link to
  <a href="http://slashdot.org/">slashdot</a>},
  'link_reference',

  q{Glossary test 3: refer to <a href="http://www.ntk.net/">ntk</a>,
   without quotes.},
  'auto_link_ref',

  q{Hmm, this should also <a href="../log/etglossary.html">work</a> },
  'out_ref_in_sq_brackets',

  q{or even <a href="http://www.ntk.net/">this</a>, using the auto link.},
  'auto_link_ref_in_sq_brackets',

  q{will <a href="http://ntk.org/">http://ntk.org/</a> still work OK?},
  'http_url_safe',

  q{Or this round-bracket <a href="../log/etglossary.html">link</a>?},
  'round_brack_link_safe',

  q{Here's another one. <img src="../ntk.gif" />.},
  'img_safe',


);

# ---------------------------------------------------------------------------

warn "IMGSIZE warning can be ignored here\n";
ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();


