# $Id: /html-treebuilder-xpath/t/pod_coverage.t 40 2006-05-15T07:42:34.182385Z mrodrigu  $

eval "use Test::Pod::Coverage 1.00 tests => 1";
if( $@)
  { print "1..1\nok 1\n";
    warn "Test::Pod::Coverage 1.00 required for testing POD coverage";
    exit;
  }

pod_coverage_ok( "HTML::TreeBuilder::XPath");
