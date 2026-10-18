use strict;
use warnings;
use Test::More;

# THE ENGINE IS INTEGER ONLY AND NEVER READS A CLOCK (D8). This file reads the C
# as shipped, needs no compiler, and looks for a floating type, a floating
# literal, a floating header or call, a clock and a random number. It then asks
# the same questions of a line that breaks every one of them, so the check is
# seen to be able to fail.

my @FILES = (glob('sen_*.c'), 'include/sen_abi.h');

sub code_of {
    my ($text) = @_;
    $text =~ s{/\*.*?\*/}{ }gs;
    $text =~ s{//[^\n]*}{ }g;
    $text =~ s{"(?:\\.|[^"\\])*"}{""}g;
    $text =~ s{'(?:\\.|[^'\\])*'}{''}g;
    return $text;
}

my %RULE = (
    'a floating type'    => qr/\b(?:float|double)\b/,
    'a floating literal' => qr/(?<![\w.])(?:\d+\.\d*|\.\d+)(?:[eE][-+]?\d+)?[fFlL]?(?![\w.])|\b\d+[eE][-+]?\d+\b/,
    'a floating header'  => qr/#\s*include\s*<(?:math|float|fenv|complex|tgmath)\.h>/,
    'a floating call'    => qr/\b(?:sqrt|pow|exp|log|floor|ceil|fabs|round|fmod|ldexp|frexp)\s*\(/,
    'a clock'            => qr/\b(?:time|clock|gettimeofday|clock_gettime|difftime|localtime|gmtime)\s*\(/,
    'a random number'    => qr/\b(?:rand|srand|random|srandom|drand48|arc4random)\s*\(/,
);

is(scalar(@FILES), 4, 'the three engine files and the header: ' . join(' ', @FILES));

for my $file (@FILES) {
    open my $fh, '<', $file or die "cannot read $file: $!";
    my $code = code_of(do { local $/; <$fh> });
    close $fh;
    for my $what (sort keys %RULE) {
        my @hits = $code =~ /($RULE{$what})/g;
        is("@hits", '', "$file has no $what");
    }
}

subtest 'the check checks' => sub {
    my $bad = code_of(qq{#include <math.h>\ndouble x = 1.5e3; float y = .5; int t = time(0) + rand(); x = sqrt(x);\n});
    for my $what (sort keys %RULE) {
        like($bad, $RULE{$what}, "a line with $what is caught");
    }
    my $fine = code_of(qq{/* 1.5 double time(0) */ int x = 16 * 3; const char *s = "rand() 2.5";\n});
    for my $what (sort keys %RULE) {
        unlike($fine, $RULE{$what}, "and $what inside a comment or a string is not");
    }
};

done_testing();
