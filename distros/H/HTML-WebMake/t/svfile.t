#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("svfile");
use Test; BEGIN { plan tests => 5 };

# ---------------------------------------------------------------------------

%patterns = (

  q{<html> <head> <title> Foo: foo foo fo fooo fooooo. (page foo) </title> </head>},
  'title',

  q{Body: <p> Foo fooo foo fo fooo foo fo fo. etc. blah.  </p>},
  'body'
);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();

