use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;

# THE ENGINE HAS NO FLOATING POINT IN IT. A value is a whole number, a chance
# is a weight over a denominator, and a search is counted in positions. That is
# why the same game is the same game on a machine with 80-bit registers, with
# quadruple-precision numbers, or with a compiler that fuses a multiply into an
# add, and why this distribution's Makefile.PL has no flag to protect it.
#
# This file reads the C as it is shipped, takes out the comments and the
# strings, and looks for anything that would make that sentence false. It
# needs no compiler. The files are found from this file's own directory, and a
# file that is missing is a failure and not a skip.

my $root = File::Spec->catdir(dirname(__FILE__), File::Spec->updir);
my @files = ('ru_engine.c', 'ru_moves.c', 'ru_search.c', File::Spec->catfile('include', 'ru_abi.h'));

sub code_of {
    my ($path) = @_;
    open my $in, '<', $path or return undef;
    my $text = do { local $/; <$in> };
    close $in;
    $text =~ s{/\*.*?\*/}{ }gs;
    $text =~ s{"(?:[^"\\]|\\.)*"}{""}g;
    $text =~ s{'(?:[^'\\]|\\.)*'}{' '}g;
    return $text;
}

for my $file (@files) {
    my $code = code_of(File::Spec->catfile($root, $file));
    ok(defined $code, "$file is there to be read") or next;
    cmp_ok(length $code, '>', 500, "$file: and has code in it once the comments are gone");

    my @types = $code =~ /\b(float|double|long\s+double|_Complex|_Float\w*|__float128)\b/g;
    is("@types", '', "$file: no floating type");

    my @literals = $code =~ /(?<![\w.])(\d+\.\d*(?:[eE][-+]?\d+)?[fFlL]?|\.\d+(?:[eE][-+]?\d+)?[fFlL]?|\d+[eE][-+]?\d+[fFlL]?)(?![\w.])/g;
    is("@literals", '', "$file: no floating literal");

    my @headers = $code =~ /#\s*include\s*<(math\.h|float\.h|fenv\.h|complex\.h|tgmath\.h|time\.h)>/g;
    is("@headers", '', "$file: no header for floating point, and none for the clock");

    my @calls = $code =~ /\b(sqrt|pow|floor|ceil|round|fabs|exp|log|clock|time|rand|srand|gettimeofday)\s*\(/g;
    is("@calls", '', "$file: no call to a floating function, a clock or a random number");
}

# THE CHECK CHECKS. The same four questions, asked of a line of C that breaks
# every one of them, so that an empty answer above is an answer.
{
    my $bad = "#include <math.h>\nstatic double half(int n) { return n * 0.5 + sqrt(2e3) + rand(); } /* float in a comment */\n";
    (my $code = $bad) =~ s{/\*.*?\*/}{ }gs;
    ok(scalar(() = $code =~ /\b(float|double)\b/g) == 1, '(a double is seen, and a float in a comment is not)');
    ok(scalar(() = $code =~ /(?<![\w.])(\d+\.\d*(?:[eE][-+]?\d+)?|\d+[eE][-+]?\d+)(?![\w.])/g) == 2, '(two floating literals are seen)');
    ok($code =~ /#\s*include\s*<math\.h>/, '(and the header)');
    ok(scalar(() = $code =~ /\b(sqrt|rand)\s*\(/g) == 2, '(and both calls)');
}

done_testing();
