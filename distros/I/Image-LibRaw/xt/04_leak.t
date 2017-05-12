use strict;
use warnings;
use Image::LibRaw;
use Test::Requires 'GTop';
use GTop;
use Test::More tests => 11;

GTop->new()->proc_mem($$)->size;

for (0..3) {
    my $i = Image::LibRaw->new();
}

my $mem = GTop->new()->proc_mem($$)->size;

for (0..10) {
    my $i = Image::LibRaw->new();
    is $mem, GTop->new()->proc_mem($$)->size;
}

