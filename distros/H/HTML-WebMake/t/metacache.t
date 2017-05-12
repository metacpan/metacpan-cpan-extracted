#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("metacache");
use Test; BEGIN { plan tests => 42 };

clear_cache_dir();

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
  'in_content_this_ref_foo',

  q{This is the bar document. The title looks like this: This is bar.},
  'in_content_this_ref_bar',

  q{<h1>This is foo.</h1>},
  'header_title_foo',

  q{<h1>This is bar.</h1>},
  'header_title_bar',

  q{Title in out item: This is foo.},
  'outside_content_this_ref_foo',

  q{Title in out item: This is bar.},
  'outside_content_this_ref_bar',

);

# ---------------------------------------------------------------------------

rewrite_bar ("XYY", "XXX");

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_foo.html", \&patterns_run_cb);
checkfile ($testname."_bar.html", \&patterns_run_cb);
ok_all_patterns();

# rewrite one input file to cause 1 output file be regenerated,
# while the others are read from cache
rewrite_bar ("XXX", "XYY");
clear_pattern_counters();
ok (wmrun ("-f data/$testname.wmk", \&patterns_run_cb));
checkfile ($testname."_foo.html", \&patterns_run_cb);
checkfile ($testname."_bar.html", \&patterns_run_cb);
ok_all_patterns();


# ---------------------------------------------------------------------------

sub rewrite_bar {
  my ($from, $to) = @_;
  open (IN, "< data/metacache.data/bar.txt") or die;
  my $all = join ('', <IN>);
  close IN;
  $all =~ s/$from/$to/g;
  open (OUT, "> data/metacache.data/bar.txt") or die;
  print OUT $all;
  close OUT;
}
