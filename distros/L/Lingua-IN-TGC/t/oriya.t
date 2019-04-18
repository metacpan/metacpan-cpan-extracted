use strict;
use warnings;
use utf8;

use Test::More tests => 5;
BEGIN { use_ok('Lingua::IN::TGC') };

my $o = Lingua::IN::TGC->new();
my @or = $o->TGC("OR", "ବୈଜ୍ଞାନିକ");

ok ($or[0] eq 'ବୈ');
ok ($or[1] eq 'ଜ୍ଞା');
ok ($or[2] eq 'ନି');
ok ($or[3] eq 'କ');
