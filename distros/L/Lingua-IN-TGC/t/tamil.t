use strict;
use warnings;
use utf8;

use Test::More tests => 5;
BEGIN { use_ok('Lingua::IN::TGC') };

my $o = Lingua::IN::TGC->new();
my @or = $o->TGC("TA", "இலக்கிய");

ok ($or[0] eq 'இ');
ok ($or[1] eq 'ல');
ok ($or[2] eq 'க்கி');
ok ($or[3] eq 'ய');
