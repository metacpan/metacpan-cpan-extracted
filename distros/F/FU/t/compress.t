use v5.36;
use Test::More;
use FU::Util qw/gzip_lib gzip_compress brotli_compress/;

like gzip_lib, qr/^(|libdeflate|zlib-ng|zlib)$/, gzip_lib;

my $incompressible;

subtest 'gzip_compress', sub {
    plan skip_all => 'No suitable gzip library found' if !gzip_lib;
    plan skip_all => 'Compress::Zlib not found' if !eval { require Compress::Zlib };

    $incompressible = Compress::Zlib::memGzip(join '', map chr(rand 256), 0..93123);

    for my $str ('', 'Hello world!', 'x'x4096, $incompressible) {
        is Compress::Zlib::memGunzip(gzip_compress(0, $str)), $str;
        is Compress::Zlib::memGunzip(gzip_compress(12, $str)), $str;
    }
};


subtest 'brotli_compress', sub {
    plan skip_all => 'libbrotlienc not available'
        if !eval { brotli_compress 6, '' } && $@ =~ /Unable to load/;

    ok length(brotli_compress 0, '') > 0;
    ok length(brotli_compress 11, '') > 0;
    # '0' does not disable compression...
    ok length(brotli_compress 0, 'Hello world!'x100) < 200;
    ok length(brotli_compress 11, 'Hello world!'x100) < 100;
};


done_testing;


__END__

# Test for leaks:

use Test::LeakTrace;
diag count_sv;
for (0..1000) {
    for my $str ('', 'Hello world!', 'x'x4096, $incompressible) {
        local $_ = gzip_lib;
        $_ = gzip_compress(0, $str);
        $_ = gzip_compress(12, $str);
        $_ = brotli_compress(0, $str);
        $_ = brotli_compress(11, $str);
    }
}
diag count_sv;


# Compare performance:

use Benchmark 'cmpthese';
open my $F, '<', 'FU.pm';
local $/ = undef;
my $data = <$F>;

cmpthese -3, {
    memGzip => 'Compress::Zlib::memGzip($data)',
    gzip_compress => 'gzip_compress(6, $data)',
    brotli_compress => 'brotli_compress(6, $data)',
};
