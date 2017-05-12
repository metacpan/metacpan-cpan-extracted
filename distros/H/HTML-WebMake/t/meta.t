#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("meta");
use Test; BEGIN { plan tests => 13 };

# ---------------------------------------------------------------------------

%patterns = (

  q{Title for foo: "This is foo."},
  'index_title_foo',

  q{Title for bar: "This is bar."},
  'index_title_bar',

  q{Foo's score: 10},
  'index_score_foo',

  q{Bar's score: 20},
  'index_score_bar',

  q{This is the foo document. The title looks like this: This is foo.},
  'in_content_meta_ref_foo',

  q{This is the bar document. The title looks like this: This is bar.},
  'in_content_meta_ref_bar',

);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();

