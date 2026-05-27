use strict;
use warnings;
use Config;
use Test::More;
use Markdown::Simple;

# ---- backend matches host expectation ----------------------------------
my $backend = Markdown::Simple::_simd_backend();
ok defined $backend, '_simd_backend returns a string';
like $backend, qr/^(?:avx2|sse2|neon|scalar)\z/,
    "backend '$backend' is one of avx2/sse2/neon/scalar";

my $arch = "$Config{archname} $Config{myarchname} $Config{archname64}";
if ($arch =~ /(?:aarch64|arm64)/i) {
    is $backend, 'neon', 'aarch64 host selects NEON backend';
}
elsif ($arch =~ /(?:x86_64|amd64)/i) {
    like $backend, qr/^(?:avx2|sse2|scalar)\z/,
        "x86_64 host selects avx2/sse2/scalar (got '$backend')";
}

# ---- _simd_force_scalar API works in-process ---------------------------
Markdown::Simple::_simd_force_scalar(1);
is Markdown::Simple::_simd_backend(), 'scalar',
    '_simd_force_scalar(1) flips backend to scalar';
Markdown::Simple::_simd_force_scalar(0);
is Markdown::Simple::_simd_backend(), $backend,
    '_simd_force_scalar(0) restores original backend';

# ---- MARKDOWN_SIMPLE_NO_SIMD env var (separate process) ----------------
SKIP: {
    skip 'no perl path', 1 unless $^X;
    my $perl = $^X;
    my @inc  = map { "-I$_" } @INC;
    my $code = 'use Markdown::Simple; print Markdown::Simple::_simd_backend()';
    my $out  = do {
        local $ENV{MARKDOWN_SIMPLE_NO_SIMD} = 1;
        qx{"$perl" @inc -e "$code"};
    };
    is $out, 'scalar', 'MARKDOWN_SIMPLE_NO_SIMD=1 forces scalar in subprocess';
}

# ---- `no_simd => 1` option path is still accepted ----------------------
my $h = Markdown::Simple::markdown_to_html("# hi\n", { no_simd => 1 });
like $h, qr{<h1>hi</h1>}, 'no_simd option still renders correctly';

done_testing;
