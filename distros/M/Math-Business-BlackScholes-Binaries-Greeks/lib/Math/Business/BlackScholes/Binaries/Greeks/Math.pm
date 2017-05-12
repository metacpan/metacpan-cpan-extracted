package Math::Business::BlackScholes::Binaries::Greeks::Math;
use strict;
use warnings;

our $VERSION = '0.05';    ## VERSION

=head1 NAME

BOM::Utility::Math::Routines

=head1 DESCRIPTION

Misc math routines.

=cut

use base qw( Exporter );
our @EXPORT_OK = qw( ddgauss dgauss );

=head2 dgauss

normal density

=cut

use constant PI => 4 * atan2(1, 1);

sub dgauss {
    my $x = shift;

    return exp(-1 * $x * $x / 2) / (2 * PI)**0.5;
}

=head2 ddgauss

dnormal density

=cut

sub ddgauss {
    my $x = shift;

    return -1 * $x * dgauss($x);
}

1;
