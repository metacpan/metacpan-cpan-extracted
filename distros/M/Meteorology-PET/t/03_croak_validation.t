use strict;
use warnings;
use Test::More;
use Meteorology::PET::Thornthwaite;

# 1. Missing constructor parameters
eval { Meteorology::PET::Thornthwaite->new() };
like($@, qr/Argument required and must be a hash ref/, "Croaks on missing hash ref");

eval {
    Meteorology::PET::Thornthwaite->new({
        LATITUDE          => 40,
        TEMPERATURE_CLIMO => [ (10) x 12 ],
        PET_UNITS         => 'mm',
    });
};
like($@, qr/TEMPERATURE_UNITS parameter is undefined/, "Croaks on missing TEMPERATURE_UNITS");

# 2. Climo array length != 12
eval {
    Meteorology::PET::Thornthwaite->new({
        LATITUDE          => 40,
        TEMPERATURE_CLIMO => [ (10) x 11 ],
        TEMPERATURE_UNITS => 'C',
        PET_UNITS         => 'mm',
    });
};
like($@, qr/must be an array ref with 12 elements/, "Croaks on invalid climo array length");

# 3. Latitude out of range
eval {
    Meteorology::PET::Thornthwaite->new({
        LATITUDE          => 95.0,
        TEMPERATURE_CLIMO => [ (10) x 12 ],
        TEMPERATURE_UNITS => 'C',
        PET_UNITS         => 'mm',
    });
};
like($@, qr/LATITUDE value must be numeric and within \[-90, 90\]/, "Croaks on latitude > 90");

# 4. Invalid pet() arguments
my $calc = Meteorology::PET::Thornthwaite->new({
    LATITUDE          => 40,
    TEMPERATURE_CLIMO => [ (10) x 12 ],
    TEMPERATURE_UNITS => 'C',
    PET_UNITS         => 'mm',
});

eval {
    $calc->pet({
        YDAY              => 400,
        NDAYS             => 30,
        TEMPERATURE       => 20,
        TEMPERATURE_UNITS => 'C',
    });
};
like($@, qr/YDAY parameter must be an integer between 1 and 366/, "Croaks on YDAY > 366");

eval {
    $calc->pet({
        YDAY              => 100,
        NDAYS             => -5,
        TEMPERATURE       => 20,
        TEMPERATURE_UNITS => 'C',
    });
};
like($@, qr/NDAYS parameter must be a positive integer/, "Croaks on negative NDAYS");

done_testing();
