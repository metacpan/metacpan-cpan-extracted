# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;

BEGIN { plan tests => 3 }

use HTML::Subtext;

ok(1);

my $INPUT = <<EOT;
<html><head><title>example</title></head><body>
<a href=\"subtext:author/name\">Author's name here</a>
<a href=\"subtext:author/email\">mailto: link here</a>
</body></html>
EOT

my %context = (
  'author/name' => 'Kaelin Colclasure',
  'author/email' => '<a href="mailto:kaelin@acm.org">kaelin@acm.org</a>'
);

my $EXPECTED = <<EOT;
<html><head><title>example</title></head><body>
Kaelin Colclasure
<a href="mailto:kaelin\@acm.org">kaelin\@acm.org</a>
</body></html>
EOT

my $p;

my @OUTPUT_ARRAY;
$p = HTML::Subtext->new('CONTEXT' => \%context,
                        'OUTPUT'  => \@OUTPUT_ARRAY);
$p->parse($INPUT);
ok(join("", @OUTPUT_ARRAY) . "\n", $EXPECTED);

my $OUTPUT_SCALAR = "";
$p = HTML::Subtext->new('CONTEXT' => \%context,
                        'OUTPUT'  => \$OUTPUT_SCALAR);
$p->parse($INPUT);
ok($OUTPUT_SCALAR . "\n", $EXPECTED);

