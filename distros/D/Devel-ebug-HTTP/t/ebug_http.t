#!perl
use strict;
use warnings;
use lib 'lib';
use Devel::ebug;
use HTTP::Request::Common;
use Test::More tests => 24;
use Test::WWW::Mechanize::Catalyst 'Devel::ebug::HTTP';

my $ebug = Devel::ebug->new();
$ebug->program("t/calc.pl");
$ebug->load;
$Devel::ebug::HTTP::ebug = $ebug;

my $root = "http://localhost";

my $m = Test::WWW::Mechanize::Catalyst->new;
$m->get_ok("$root/");
is($m->ct, "text/html");
$m->title_is('t/calc.pl main(t/calc.pl#3) my $q = 1;');
$m->content_contains("Step");
$m->content_contains("Next");
$m->content_contains("t/calc.pl main(t/calc.pl#3)");
$m->content_contains("#!perl");
$m->content_contains("Variables in main");
$m->content_contains("Stack trace");
$m->content_contains("STDOUT");
$m->content_contains("STDERR");
$m->content_contains("Devel::ebug");
$m->content_contains($Devel::ebug::VERSION);

# $q not defined yet
$m->get_ok("$root/ajax_variable/\$q");
is($m->ct, "text/xml");
is(
  $m->content, q|<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<response>
  <variable>$q</variable>
  <value><![CDATA[Not defined]]></value>
</response>
  |
);

# 2+3 = 5
$m->request(POST "$root/ajax_eval", [eval => '2+3', myaction => 'Eval']);
#$m->get_ok("$root/ajax_eval?eval=2+3&myaction=Eval");
is($m->ct, "text/html");
is($m->content, "5");

# hit "Step"
$m->request(POST 'http://somewhere/foo', [sequence => 3, myaction => 'Step']);
is($m->ct, "text/html");
$m->title_is('t/calc.pl main(t/calc.pl#4) my $w = 2;');
$m->content_contains("t/calc.pl main(t/calc.pl#4)");

# $q is now defined, and 1
$m->get_ok("$root/ajax_variable/\$q");
is($m->ct, "text/xml");
is(
  $m->content, q|<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<response>
  <variable>$q</variable>
  <value><![CDATA[1<br/>]]></value>
</response>
  |
);