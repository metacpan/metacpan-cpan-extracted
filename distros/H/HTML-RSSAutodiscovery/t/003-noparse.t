use strict;
use Test::More;

plan tests => 5;

SKIP: {

  eval {
    require XMLRPC::Lite;
  };
    
  if ($@) {
    skip("XMLRPC::Lite not installed",5);
  }
  
  my $url   = "scripting";
  my $links = undef;
  my $count = undef;
  
  use_ok("HTML::RSSAutodiscovery");
  
  my $html = HTML::RSSAutodiscovery->new();
  isa_ok($html,"HTML::RSSAutodiscovery");
  
  eval { $links = $html->locate($url,{noparse=>1}); };
  is($@,'',"Parsed $url");
  
  cmp_ok(ref($links),"eq","ARRAY");
  
  $count = scalar(@$links);
  cmp_ok($count,">",0,"$count feed(s)");
}


