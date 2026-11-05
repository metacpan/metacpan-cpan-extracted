use strict;
use warnings;
use Test::More;
use Meteorology::PET::Thornthwaite;

my @standard_climo_c = ( -2, 0, 5, 10, 16, 21, 24, 23, 19, 13, 6, 0 );

my $calc_dc = Meteorology::PET::Thornthwaite->new({
    LATITUDE          => 38.9,
    TEMPERATURE_CLIMO => \@standard_climo_c,
    TEMPERATURE_UNITS => 'C',
    PET_UNITS         => 'mm',
});

ok($calc_dc, "Constructed scalar PET object");
cmp_ok($calc_dc->{TEI}, '>', 0, "Pre-computed TEI is positive");

# 1. Below freezing (Frozen ground -> PET == 0)
my $pet_frozen = $calc_dc->pet({
    YDAY              => 15,
    NDAYS             => 31,
    TEMPERATURE       => -3.5,
    TEMPERATURE_UNITS => 'C',
});
is($pet_frozen, 0, "Sub-zero daily temperature produces 0 PET");

# 2. Normal Thornthwaite range (0 < T < 26.5 C)
my $pet_norm = $calc_dc->pet({
    YDAY              => 196,
    NDAYS             => 31,
    TEMPERATURE       => 24.0,
    TEMPERATURE_UNITS => 'C',
});
cmp_ok($pet_norm, '>', 0, "Normal summer month temperature produces positive PET");

# 3. High Temperature range (T >= 26.5 C)
my $pet_hot = $calc_dc->pet({
    YDAY              => 196,
    NDAYS             => 31,
    TEMPERATURE       => 30.0,
    TEMPERATURE_UNITS => 'C',
});
# Expected formula: (-415.85 + 32.25 * 30 - 0.43 * (30**2)) * (31 / 30)
my $expected_hot = (-415.85 + 32.25 * 30.0 - 0.43 * (30.0**2)) * (31 / 30);
is_deeply(sprintf("%.4f", $pet_hot), sprintf("%.4f", $expected_hot), "Huang et al. polynomial applied for T >= 26.5 C");

# 4. Zero/Negative TEI edge case (e.g. Arctic / Permafrost climo where TEI == 0)
my $calc_arctic = Meteorology::PET::Thornthwaite->new({
    LATITUDE          => 75.0,
    TEMPERATURE_CLIMO => [ (-10) x 12 ],
    TEMPERATURE_UNITS => 'C',
    PET_UNITS         => 'mm',
});
is($calc_arctic->{TEI}, 0, "Arctic climatology yields TEI == 0");

my $pet_arctic_warm_day = $calc_arctic->pet({
    YDAY              => 180,
    NDAYS             => 30,
    TEMPERATURE       => 10.0,
    TEMPERATURE_UNITS => 'C',
});
is($pet_arctic_warm_day, 0, "Thornthwaite range with TEI <= 0 safely returns 0 without divide-by-zero");

# 5. Arctic station during a hot anomaly (T >= 26.5 C should still compute Huang correction)
my $pet_arctic_heatwave = $calc_arctic->pet({
    YDAY              => 180,
    NDAYS             => 30,
    TEMPERATURE       => 28.0,
    TEMPERATURE_UNITS => 'C',
});
cmp_ok($pet_arctic_heatwave, '>', 0, "Huang polynomial computes PET during heatwave even with TEI == 0");

done_testing();
