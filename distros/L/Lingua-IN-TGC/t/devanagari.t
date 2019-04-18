use strict;
use warnings;
use utf8;

use Test::More tests => 4;
BEGIN { use_ok('Lingua::IN::TGC') };

my $o = Lingua::IN::TGC->new();
my @or = $o->TGC("DE", "मन्दिर");

ok ($or[0] eq 'म');
ok ($or[1] eq 'न्दि');
ok ($or[2] eq 'र');
