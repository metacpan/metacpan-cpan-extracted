use strict;
use warnings;
use Test::More tests => 100 + 5;
BEGIN { use_ok('Math::FFTW') };

my @data = (1..100);
my $coeff = Math::FFTW::fftw_dft_real2complex_1d(\@data);
ok(ref($coeff) eq 'ARRAY');
ok(@$coeff == (@data/2+1)*2);
my $res = Math::FFTW::fftw_idft_complex2real_1d($coeff);
ok(ref($res) eq 'ARRAY');
ok(@$res == @data);
foreach my $i (0..$#data) {
    ok($res->[$i]+0.01 > $data[$i] && $res->[$i]-0.01 < $data[$i]);
}

