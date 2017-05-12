#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok( { also_private => [
  # These methods are documented in HTML::WikiConverter::Dialects
  qr/
     get_elem_contents
    |get_wiki_page
    |get_attr_str
    |is_camel_case
    |rule
    |rules
    |attribute
    |attributes
    |preprocess_node
    |postprocess_output
    |caption2para
    |strip_aname
  /x
] } );
