#!/usr/bin/perl
use lib qw (lib ../lib);
use warnings;
use strict;
use I18NFool::Extractor;
use I18NFool::ExtractorMerger;

use Test::More 'no_plan';

my $xml1 = <<EOF;
<html xmlns:i18n="http://xml.zope.org/namespaces/i18n">
  <body>
    <div i18n:translate=""
         i18n:domain="bar"
    >XML1, bar</div>
    <div xmlns:localize="http://xml.zope.org/namespaces/i18n"
         localize:domain="foo"
         localize:translate=""
    >XML1, foo</div>
    <div i18n:translate="">XML1, default</div>
  </body>
</html>
EOF

my $xml2 = <<EOF;
<html xmlns:i18n="http://xml.zope.org/namespaces/i18n">
  <body>
    <div i18n:translate=""
         i18n:domain="bar"
    >XML2, bar</div>
    <div xmlns:localize="http://xml.zope.org/namespaces/i18n"
         localize:domain="foo"
         localize:translate=""
    >XML2, foo</div>
    <div i18n:translate="">XML2, default</div>
  </body>
</html>
EOF


my $res1 = I18NFool::Extractor->process ($xml1);
my $res2 = I18NFool::Extractor->process ($xml2);
my $res  = I18NFool::ExtractorMerger->process ($res1, $res2);

ok ($res->{'bar'}, 'bar domain exists');
ok ($res->{'bar'}->{'XML1, bar'}, 'xml1, bar');
ok ($res->{'bar'}->{'XML2, bar'}, 'xml2, bar');

ok ($res->{'foo'}, 'foo domain exists');
ok ($res->{'foo'}->{'XML1, foo'}, 'xml1, foo');
ok ($res->{'foo'}->{'XML2, foo'}, 'xml2, foo');

ok ($res->{'default'}, 'default domain exists');
ok ($res->{'default'}->{'XML1, default'}, 'xml1, default');
ok ($res->{'default'}->{'XML2, default'}, 'xml2, default');

1;

__END__
