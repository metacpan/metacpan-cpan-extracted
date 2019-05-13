use strict; use warnings;
use lib -e 't' ? 't' : 'test';
use diagnostics;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;
use Test::More;

my $c_text = <<'EOC';
SV *sum(SV *array) {
    int total = 0;
    int numelts, i;
    if ((!SvROK(array))
        || (SvTYPE(SvRV(array)) != SVt_PVAV)
        || ((numelts = av_len((AV *)SvRV(array))) < 0)
    ) {
        return &PL_sv_undef;
    }
    for (i = 0; i <= numelts; i++) {
        total += SvIV(*av_fetch((AV *)SvRV(array), i, 0));
    }
    return newSViv(total);
}
EOC
Inline->bind(C => $c_text);

is sum([(1..4)]), 10, 'correct sum';
is sum(undef), undef, 'return undef when given undef';
is sum('hello'), undef, 'return undef when given non-ref';
is sum([]), undef, 'return undef when given empty list';

done_testing;
