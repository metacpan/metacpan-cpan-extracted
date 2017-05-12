use strict;
use warnings;

use Test::More tests => 6;

use Test::Fatal;

use File::Open qw(fsysopen_nothrow fopendir_nothrow fopen_nothrow fsysopen fopendir fopen);

my $evil = __FILE__ . "\0";
my $evildir = ".\0";

like $_, qr/\Q: $evil: / for
    exception { fopen $evil, 'r' },
    exception { fsysopen $evil, 'r' },
;
like $_, qr/\Q: $evildir: / for
    exception { fopendir $evildir },
;

is $_, undef for
    fopen_nothrow($evil, 'r'),
    fsysopen_nothrow($evil, 'r'),
    fopendir_nothrow($evildir),
;
