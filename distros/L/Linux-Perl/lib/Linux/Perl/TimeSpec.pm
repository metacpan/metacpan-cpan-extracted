package Linux::Perl::TimeSpec;

use strict;
use warnings;

use constant {
    _TEMPLATE => 'L!L!',
    _NANO => 1_000_000_000,
};

sub from_float {
    my ($float) = @_;

    my $int      = int $float;
    my $fraction = $float - $int;

    return pack _TEMPLATE(), $int, ( $fraction * _NANO() );
}

sub to_float {
    my ($str) = @_;

    my ( $secs, $nsecs ) = unpack _TEMPLATE(), $str;

    return $secs + ( $nsecs / _NANO() );
}

1;
