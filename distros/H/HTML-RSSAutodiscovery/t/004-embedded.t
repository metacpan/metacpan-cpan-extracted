use strict;
use Test::More;

eval "require XML::RSS";

if ($@) {
   plan tests => "none";
   exit;
}

plan tests => 5;

my $url   = "http://www.diveintomark.org";
my $links = undef;
my $count = undef;

use_ok("HTML::RSSAutodiscovery");

my $html = HTML::RSSAutodiscovery->new();

isa_ok($html,"HTML::RSSAutodiscovery");

eval { $links = $html->locate($url,{embedded=>1,embedded_and_remote=>1}); };
is($@,'',"Parsed $url");

cmp_ok(ref($links),"eq","ARRAY");

$count = scalar(@$links);
cmp_ok($count,">",0,"$count feed(s)");



