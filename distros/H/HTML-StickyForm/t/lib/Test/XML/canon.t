#!/usr/bin/perl

use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 6;

ok(eval { require Test::XML::Canon; },'loaded module')
  or diag $@;
ok(*canon_xml=\&Test::XML::Canon::canon_xml,'"import"');

is(canon_xml('<foo/>'),'<foo></foo>','simple');
is(canon_xml('<foo abc="def"/>'),'<foo abc="def"></foo>','one attr');
is(canon_xml('<foo abc="def" ghi="jkl"/>'),'<foo abc="def" ghi="jkl"></foo>','two attrs');
is(canon_xml('<foo ghi="jkl" abc="def" />'),'<foo abc="def" ghi="jkl"></foo>','two attrs order');
