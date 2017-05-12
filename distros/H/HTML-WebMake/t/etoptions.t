#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("etoptions");
use Test; BEGIN { plan tests => 7 };

# ---------------------------------------------------------------------------

%patterns = (
q{This <strong>is</strong> a test.}, 'one_char1',
q{<em>seriously!</em>}, 'one_char2',
q{And <a href="/foo/bar/baz/blargh.html">a link</a>.}, 'rel_link'
);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();

