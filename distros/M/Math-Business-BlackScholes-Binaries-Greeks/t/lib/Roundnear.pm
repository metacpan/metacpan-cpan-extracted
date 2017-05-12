package Roundnear;
use strict;
use warnings;

require Exporter;
use POSIX;

BEGIN {
    our @ISA    = qw(Exporter);
    our @EXPORT = qw(roundnear);
}

#cf. Math::Round
my $halfdec = do {
    my $halfhex = unpack('H*', pack('d', 0.5));
    if (   substr($halfhex, 0, 2) ne '00'
        && substr($halfhex, -2) eq '00')
    {
        substr($halfhex, -4) = '1000';
    } else {
        substr($halfhex, 0, 4) = '0010';
    }
    unpack('d', pack('H*', $halfhex));
};

sub roundnear {
    my ($targ, $input) = @_;

    return $input if (not defined $input);

    my $rounded = $input;

    # rounding to 0, doesnt really make sense, but viewing it as a limit
    # process it means do not round at all
    if ($targ != 0) {
        $rounded =
            ($input >= 0)
            ? $targ * int(($input + $halfdec * $targ) / $targ)
            : $targ * ceil(($input - $halfdec * $targ) / $targ);
    }

    # Avoid any possible -0 rounding situations.
    return 1 * $rounded;
}

1;

