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
    <div i18n:translate=""
    >This is a first string to translate.</div>
    <div xmlns:localize="http://xml.zope.org/namespaces/i18n"
         localize:translate=""
    >This is a second string to translate.</div>
  </body>
</html>
EOF

my $res = I18NFool::Extractor->process ($xml);
ok ($res                                                       => 'res is defined'        );
ok ($res->{default}                                            => 'default domain exists' );
ok ($res->{default}->{'This is a first string to translate.'}  => 'second string exists'  );
ok ($res->{default}->{'This is a second string to translate.'} => 'second string exists'  );

1;

__END__
