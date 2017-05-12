#!/usr/bin/perl -w

use lib '.'; use lib '../lib'; use lib 't';
use WMTest; webmake_t_init("download_tag");
use Test; BEGIN { plan tests => 28 };

system ("mkdir -p log/d1/d1 log/d2 log/d3");

open (OUT, ">log/download_tst");
$_ = ('z' x 80) . "\n";
print OUT ($_ x 80);
close OUT;

open (OUT, ">log/d2/download_tst_2");
$_ = ('z' x 100) . "\n";
print OUT ($_ x 100);
close OUT;

open (OUT, ">log/d3/download_tst_3");
$_ = ('z' x 100) . "\n";
print OUT ($_ x 100);
close OUT;

# ---------------------------------------------------------------------------

$file = q{
  <webmake>
  <use plugin=download_tag />
  <option name="FileSearchPath" value="log/d3" />

  <content name="full_dl_template">
      A:${download.name}
      B:${download.mdate}
      C:${download.mtime}
      D:${download.size_in_k}
      E:${download.size}
      F:${download.owner}
      G:${download.group}
      H:${download.tag_attrs}
  </content>

  <content name="foo">
    This is a test: <download file="download_tst" />

    test B: <download file="download_tst" class="foo" />

    test C: <download file="download_tst"
    text="${download.mtime} ${download.size}" />

    test D:
    <download file="download_tst" text="${full_dl_template}" />

  </content>

  <content name="bar">
  <download file="log/download_tst" />
  <download file="log/d2/download_tst_2" />
  <download file="download_tst_3" />
  </content>

  <out file="log/download_tag.html">${foo}${bar}</out>
  <out file="log/d1/download_tag.html">${bar}</out>
  <out file="log/d1/d1/download_tag.html">${bar}</out>
  <out file="log/d2/download_tag.html">${bar}</out>
  </webmake>
};

# ---------------------------------------------------------------------------

%patterns = (

  q{This is a test: <a href="download_tst">download_tst (7k)</a>},
  'test_a',

  q{test B: <a href="download_tst" class="foo">download_tst (7k)</a>},
  'test_b',

  q{test C:},
  'test_c_pt1',

  q{6480 test D:},
  'test_c_pt2',

  q{test D:
  A:download_tst},
  'test_d_pt1',

  q{D:7
  E:6480},
  'test_d_pt2',

  q{<a href="../download_tst">download_tst (7k)</a> <a
  href="../d2/download_tst_2">download_tst_2 (10k)</a> <a
  href="../d3/download_tst_3">download_tst_3 (10k)</a>}, 'd1_file',


  q{<a href="../../download_tst">download_tst (7k)</a> <a
  href="../../d2/download_tst_2">download_tst_2 (10k)</a> <a
  href="../../d3/download_tst_3">download_tst_3 (10k) </a>}, 'd1_d1_file',


  q{<a href="../download_tst">download_tst (7k)</a> <a
  href="download_tst_2">download_tst_2 (10k)</a> <a
  href="../d3/download_tst_3">download_tst_3 (10k)</a>}, 'd2_file',



);

# ---------------------------------------------------------------------------

use HTML::WebMake::Main;
sub chkcanon {
  my ($fname, $reldir, $expected) = @_;

  my $out = HTML::WebMake::Main::canon_path ($fname, $reldir);
  print "\tcanon_path ($fname, $reldir) => $out\n";
  if ($out ne $expected) { print "\tNOPE: should be \"$expected\"\n"; }
  ($out eq $expected);
}

ok (chkcanon ("../../d1/d2/foo", "d1/d2", "foo"));
ok (chkcanon ("../../d1/d3/foo", "d1/d2", "../d3/foo"));
ok (chkcanon ("../../d1/d2/d3/d4/foo", "d1/d2", "d3/d4/foo"));
ok (chkcanon ("d1/d2/foo", "d1/d2", "d1/d2/foo"));
ok (chkcanon ("../../d1/d3/d4/foo", "d1/d2", "../d3/d4/foo"));
ok (chkcanon ("../../foo", "d1/d2", "../../foo"));
ok (chkcanon ("d2/foo", "d1/d2", "d2/foo"));
ok (chkcanon ("./log/../data/test.gif", ".", "data/test.gif"));

# some canon_path tests for CGI use
ok (chkcanon ("!!WMVIEWCGI!!/d2/foo/../../index.html", "", "!!WMVIEWCGI!!/index.html"));

wmfile ($file);
ok (wmrun ("-F -f log/test.wmk", \&patterns_run_cb));
checkfile ("d1/download_tag.html", \&patterns_run_cb);
checkfile ("d1/d1/download_tag.html", \&patterns_run_cb);
checkfile ("d2/download_tag.html", \&patterns_run_cb);
ok_all_patterns();
