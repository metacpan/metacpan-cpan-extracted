use strict;
use warnings;
use utf8;

use Test::More tests => 6;
BEGIN { use_ok('Lingua::IN::TGC') };

my $o = Lingua::IN::TGC->new();
my @or = $o->TGC("KN", "ಕನ್ನಡಿಗರು");

ok ($or[0] eq 'ಕ');
ok ($or[1] eq 'ನ್ನ');
ok ($or[2] eq 'ಡಿ');
ok ($or[3] eq 'ಗ');
ok ($or[4] eq 'ರು');
