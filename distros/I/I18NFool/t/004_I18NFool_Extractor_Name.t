#!/usr/bin/perl
use lib qw (lib ../lib);
use warnings;
use strict;
use I18NFool::Extractor;

use Test::More 'no_plan';

# okay, first let us test the namespace support...
my $xml = <<EOF;
<html xmlns:i18n="http://xml.zope.org/namespaces/i18n">
  <body>
    <div i18n:translate="">Hello <span i18n:name="user">Laurent</span>, how are you today?</div>
  </body>
</html>
EOF

my $res = I18NFool::Extractor->process ($xml);
ok ($res, 'res is true');
ok ($res->{default}, 'default domain is true');
ok ($res->{default}->{'Hello ${user}, how are you today?'});

1;

__END__
