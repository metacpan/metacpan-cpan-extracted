use strict;
use Test::More tests => 1;
use Image::LibRaw;

my $i = Image::LibRaw->new;
like($i->version, qr{^0});

diag $i->version;

