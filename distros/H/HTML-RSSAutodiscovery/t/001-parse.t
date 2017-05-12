use strict;

use Test::More;
plan tests => 5;

my $url   = "http://www.diveintomark.org/";
my $links = undef;
my $count = undef;

use_ok("HTML::RSSAutodiscovery");

my $html = HTML::RSSAutodiscovery->new();

isa_ok($html,"HTML::RSSAutodiscovery");

eval { $links = $html->parse($url); };
is($@,'',"Parsed $url");

cmp_ok(ref($links),"eq","ARRAY");

$count = scalar(@$links);
cmp_ok($count,">",0,"$count feed(s)");



