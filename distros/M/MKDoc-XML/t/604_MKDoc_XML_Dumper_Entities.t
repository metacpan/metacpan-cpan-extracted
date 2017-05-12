#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Dumper;

my $xml = <<EOF;
<perl>
  <hash id="id_153607344" bless="flo::editor::Text">
    <item key="data">First Impressions
=================
 
Okay, I am not allowed to disclosed information about &quot;all Google software,
    </item>
  </hash>
</perl>
EOF
 
my $pl  = MKDoc::XML::Dumper->xml2perl ($xml);

ok (ref $pl);
like ($pl->{data}, qr/\"/);

1;


__END__
