use strict;
use warnings;

use HTML::HeadParser ();
use Test::More tests => 1;

my $h;
my $p = HTML::HeadParser->new($h);
$p->parse(<<EOT);
<title>Stupid example</title>
<base href="http://www.sn.no/libwww-perl/">
Normal text starts here.
EOT

$h = $p->header;
undef $p;
is($h->title, "Stupid example");
