#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("implicitmetas");
use Test; BEGIN { plan tests => 34 };

clear_cache_dir();

# ---------------------------------------------------------------------------

%patterns = (

q{The winners are:
 - This is foo
 - This is bar
 - this is baz
 - This is blag
 - This is gab
 - This is boo
 - This is floo
 }, 'winners',

q{Title: This is foo // }, 'title_foo',

q{Title: This is bar // }, 'title_bar',

q{Title: this is baz // }, 'title_baz',

q{Title: This is blag // }, 'title_blag',

q{Title: This is gab // }, 'title_gab',

q{Title: This is boo //}, 'title_boo',

q{Title: This is floo // <a name=},
	'title_floo',

);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_1.html", \&patterns_run_cb);
checkfile ($testname."_2.html", \&patterns_run_cb);
checkfile ($testname."_3.html", \&patterns_run_cb);
checkfile ($testname."_4.html", \&patterns_run_cb);
checkfile ($testname."_5.html", \&patterns_run_cb);
checkfile ($testname."_6.html", \&patterns_run_cb);
checkfile ($testname."_7.html", \&patterns_run_cb);
# etc.
ok_all_patterns();

# now with the cache
clear_pattern_counters();
ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_1.html", \&patterns_run_cb);
checkfile ($testname."_2.html", \&patterns_run_cb);
checkfile ($testname."_3.html", \&patterns_run_cb);
checkfile ($testname."_4.html", \&patterns_run_cb);
checkfile ($testname."_5.html", \&patterns_run_cb);
checkfile ($testname."_6.html", \&patterns_run_cb);
checkfile ($testname."_7.html", \&patterns_run_cb);
# etc.
ok_all_patterns();

