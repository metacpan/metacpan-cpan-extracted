#!perl

use strict;
use warnings;
use Interchange::Search::Solr;
use Test::More tests => 3;

like serialize({ test => 'a' }),
  qr{<add><doc><field name="test">a</field></doc></add>}, "serialized ok";

like serialize({ test => [qw/a b/] }),
  qr{<add><doc><field name="test">a</field><field name="test">b</field></doc></add>}, "multivalued serialized ok";

like serialize([ { test => [qw/a b/] }, { test2 => 'a' } ]),
  qr{<add><doc><field name="test">a</field><field name="test">b</field></doc><doc><field name="test2">a</field></doc></add>},
  "Arrayref serialized correctly";

sub serialize {
    return Interchange::Search::Solr->_build_xml_add_op(shift);
}
