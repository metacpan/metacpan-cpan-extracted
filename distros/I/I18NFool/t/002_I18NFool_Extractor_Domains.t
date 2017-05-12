#!/usr/bin/perl
use lib qw (lib ../lib);
use warnings;
use strict;
use I18NFool::Extractor;

use Test::More 'no_plan';

my $xml = <<EOF;
<html xmlns:i18n="http://xml.zope.org/namespaces/i18n">
  <body>
    <div i18n:translate=""
         i18n:domain="bar"
    >This is a first string to translate.</div>
    <div xmlns:localize="http://xml.zope.org/namespaces/i18n"
         localize:domain="foo"
         localize:translate=""
    >This is a second string to translate.</div>
    <div i18n:translate="">More stuff.</div>
  </body>
</html>
EOF

my $res = I18NFool::Extractor->process ($xml);
ok ($res->{'default'} => 'default domain exists');
ok ($res->{'bar'}     => 'bar domain exists');
ok ($res->{'foo'}     => 'foo domain exists');


1;

__END__
