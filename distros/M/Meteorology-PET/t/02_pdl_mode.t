use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use PDL; 1;" or plan skip_all => "PDL is required for testing PDL vector mode";
}

use Meteorology::PET::Thornthwaite;

# Create a 2x2 grid:
# Cell (0,0): Washington DC (Northern Hemisphere, Normal)
# Cell (1,0): Buenos Aires  (Southern Hemisphere, Normal)
# Cell (0,1): Extreme Arctic (TEI == 0)
# Cell (1,1): Sahara (Hot climo)
my $lats = pdl([
    [ 38.9, -34.6 ],
    [ 78.0,  25.0 ]
]);

# Build a 12-month array of 2x2 PDLs
my @climo_pdls;
for my $m (0 .. 11) {
    # Monthly temps varying across the grid
    push @climo_pdls, pdl([
        [ 2.0 + $m * 2,  22.0 - $m * 1.5 ],
        [ -20.0 + $m,    18.0 + $m * 1.8 ]
    ]);
}

my $pdl_calc = Meteorology::PET::Thornthwaite->new({
    LATITUDE          => $lats,
    TEMPERATURE_CLIMO => \@climo_pdls,
    TEMPERATURE_UNITS => 'C',
    PET_UNITS         => 'mm',
});

ok($pdl_calc, "Initialized PDL constructor");
is($pdl_calc->{PDL_MODE}, 1, "Object successfully set to PDL mode");

# Test grid-wide calculation with mixed temperature boundaries:
# - Below zero
# - Normal Thornthwaite range
# - Hot temperature (Huang et al.)
my $daily_temps = pdl([
    [ -5.0, 20.0 ],   # [Frozen cell, Normal cell]
    [  5.0, 32.0 ]    # [Arctic thaw cell, Hot cell]
]);

my $pet_grid = $pdl_calc->pet({
    YDAY              => 180,
    NDAYS             => 30,
    TEMPERATURE       => $daily_temps,
    TEMPERATURE_UNITS => 'C',
});

isa_ok($pet_grid, 'PDL');
is_deeply([ $pet_grid->dims ], [ 2, 2 ], "Output PET grid dimensions match latitude grid");

# Cell (0,0): T = -5.0 C -> PET must be 0
is($pet_grid->at(0, 0), 0, "Frozen grid cell outputs 0 PET");

# Cell (1,0): T = 20.0 C in Southern Hemisphere -> Positive PET
cmp_ok($pet_grid->at(1, 0), '>', 0, "Southern hemisphere grid cell outputs positive PET");

# Cell (1,1): T = 32.0 C -> Huang et al. correction applies
my $expected_sahara = (-415.85 + 32.25 * 32.0 - 0.43 * (32.0**2)) * (30 / 30);
is_deeply(sprintf("%.3f", $pet_grid->at(1, 1)), sprintf("%.3f", $expected_sahara), "Huang et al. polynomial applies to hot grid cell");

# Ensure no NaNs or Infs exist anywhere in the piddle
my $bad_count = $pet_grid->isbad->sum + ($pet_grid != $pet_grid)->sum;
is($bad_count, 0, "Piddle result contains zero NaN or Bad values");

done_testing();
