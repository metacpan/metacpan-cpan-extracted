use Test::More tests => 3;
BEGIN { use_ok('HTML::BBCode'); }

use strict;

my $bbc = new HTML::BBCode;
isa_ok($bbc, 'HTML::BBCode');

is($bbc->parse(""), "", "Empty string test");
