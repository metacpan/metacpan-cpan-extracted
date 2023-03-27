use Test2::V0;
use File::Open qw(fsysopen_nothrow fopendir_nothrow fopen_nothrow fsysopen fopendir fopen);

my $evil = __FILE__ . "\0";
my $evildir = ".\0";

like $_, qr/\Q: $evil: / for
    dies { fopen $evil, 'r' },
    dies { fsysopen $evil, 'r' },
;
like $_, qr/\Q: $evildir: / for
    dies { fopendir $evildir },
;

is $_, undef for
    fopen_nothrow($evil, 'r'),
    fsysopen_nothrow($evil, 'r'),
    fopendir_nothrow($evildir),
;

done_testing;
