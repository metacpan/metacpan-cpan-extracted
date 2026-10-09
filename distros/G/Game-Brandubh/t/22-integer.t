use strict;
use warnings;
use Test::More;
use FindBin;

# THERE IS NO FLOATING POINT IN THE ENGINE. A score, a key and a count are all
# integers, which is why the same position gives the same move on every machine
# and every compiler, and why this distribution needs none of the build flags a
# sibling needed to make its doubles round alike.
#
# This reads the C. THE COMMENTS ARE STRIPPED FIRST: the files say "no floats"
# in so many words, and a search for the word that did not strip them would
# find its own explanation and fail, or be loosened until it found nothing.

my $root = "$FindBin::Bin/..";
my @files = (glob("$root/bd_*.c"), "$root/include/bd_abi.h", "$root/Brandubh.xs");

sub code_of {
    my ($text) = @_;
    $text =~ s{/\*.*?\*/}{ }gs;
    $text =~ s{^#(?!\s*(?:define|include|if|ifdef|ifndef|else|elif|endif|undef|line|pragma)\b).*$}{}mg;
    $text =~ s{"(?:[^"\\]|\\.)*"}{""}g;
    return $text;
}

cmp_ok(scalar(@files), '>=', 6, 'the C files were found: ' . scalar(@files));

for my $file (@files) {
    open my $fh, '<', $file or die "$file: $!";
    my $code = code_of(do { local $/; <$fh> });
    (my $name = $file) =~ s{.*/}{};
    my @found = $code =~ /\b(float|double|long\s+double|NV|SvNV\w*|newSVnv|sqrt|pow|floor|ceil|fabs)\b/g;
    is("@found", '', "$name: no floating point type, call or macro");
    unlike($code, qr/\b[0-9]+\.[0-9]+(?:[eE][-+]?[0-9]+)?[fFlL]?\b/, "$name: and no floating point number written out");
}

# the instrument, checked: it must find what it is looking for when it is
# there, and must not find it in a comment or a string
{
    my $sample = <<'C';
/* this comment says double and 3.14 and must not count */
static int honest(void) { return 2; }
# an XS comment that says float
static const char *words = "double trouble 2.5";
C
    my $code = code_of($sample);
    unlike($code, qr/\b(?:float|double)\b/, 'a float named only in a comment or a string is not found');
    unlike($code, qr/\b[0-9]+\.[0-9]+\b/, 'nor is a number written there');

    my $guilty = code_of("static double half(void) { return 0.5; }\n");
    like($guilty, qr/\bdouble\b/, 'a double in the code is found');
    like($guilty, qr/\b[0-9]+\.[0-9]+\b/, 'and so is a number with a point in it');
}

done_testing();
