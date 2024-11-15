package Geo::Coordinates::DecimalDegrees;

require Exporter;
require Carp;

@ISA = qw(Exporter);

@EXPORT = qw( decimal2dms decimal2dm dms2decimal dm2decimal
              dec2dms     dec2dm     dms2dec     dm2dec);

$VERSION = '0.11';

use strict;
use warnings;

sub decimal2dms {
    my ($decimal) = @_;

    my $sign = $decimal <=> 0;
    my $degrees = int($decimal);

    # convert decimal part to minutes
    my $dec_min = abs($decimal - $degrees) * 60;
    my $minutes = int($dec_min);
    my $seconds = ($dec_min - $minutes) * 60;

    return ($degrees, $minutes, $seconds, $sign);
}

sub decimal2dm {
    my ($decimal) = @_;

    my $sign = $decimal <=> 0;
    my $degrees = int($decimal);
    my $minutes = abs($decimal - $degrees) * 60;

    return ($degrees, $minutes, $sign);
}

sub dms2decimal {
    my ($degrees, $minutes, $seconds) = @_;
    my $decimal;

    if ($degrees >= 0) {
	$decimal = $degrees + $minutes/60 + $seconds/3600;
    } else {
	$decimal = $degrees - $minutes/60 - $seconds/3600;
    }

    return $decimal;
}

sub dm2decimal {
    my ($degrees, $minutes) = @_;

    return dms2decimal($degrees, $minutes, 0);
}

*dec2dms = \&decimal2dms;
*dec2dm = \&decimal2dm;
*dms2dec = \&dms2decimal;
*dm2dec = \&dm2decimal;

1;

=head1 NAME

Geo::Coordinates::DecimalDegrees - convert between degrees/minutes/seconds and decimal degrees

=head1 SYNOPSIS

  use Geo::Coordinates::DecimalDegrees;
  ($degrees, $minutes, $seconds, $sign) = decimal2dms($decimal_degrees);
  ($degrees, $minutes, $seconds, $sign) = dec2dms($decimal_degrees);

  ($degrees, $minutes, $sign) = decimal2dm($decimal_degrees);
  ($degrees, $minutes, $sign) = dec2dm($decimal_degrees);

  $decimal_degrees = dms2decimal($degrees, $minutes, $seconds);
  $decimal_degrees = dms2dec($degrees, $minutes, $seconds);

  $decimal_degrees = dm2decimal($degrees, $minutes);
  $decimal_degrees = dm2dec($degrees, $minutes);

=head1 DESCRIPTION

Latitudes and longitudes are most often presented in two common
formats: decimal degrees, and degrees, minutes and seconds.  There are
60 minutes in a degree, and 60 seconds in a minute.  In decimal
degrees, the minutes and seconds are presented as a fractional number
of degrees.  For example, 1 degree 30 minutes is 1.5 degrees, and 30
minutes 45 seconds is 0.5125 degrees.

This module provides functions for converting between these two
formats.

=head1 FUNCTIONS

This module provides the following functions, which are all exported
by default when you call C<use Geo::Coordinates::DecimalDegrees;>:

=over 4

=item decimal2dms($decimal_degrees)

Converts a floating point number of degrees to the equivalent number
of degrees, minutes, and seconds, which are returned as a 3-element
list.  Typically used as follows:

  ($degrees, $minutes, $seconds) = decimal2dms($decimal_degrees);

If $decimal_degrees is negative, only $degrees will be negative.
$minutes and $seconds will always be positive.

If $decimal_degrees is between 0 and -1, $degrees will be returned as
0. If you need to know the sign in these cases, you can use this
longer version, where $sign is 1, 0, or -1 depending on whether
$decimal_degrees is positive, 0, or negative:

  ($degrees, $minutes, $seconds, $sign) = decimal2dms($decimal_degrees);

=item dec2dms($decimal_degrees)

An alias for decimal2dms().

=item decimal2dm($decimal_degrees)

Converts a floating point number of degrees to the equivalent number
of degrees and minutes which are returned as a 2-element list.
Typically used as follows:

  ($degrees, $minutes) = decimal2dm($decimal_degrees);

If $decimal_degrees is negative, only $degrees will be negative.
$minutes will always be positive.

If $decimal_degrees is between 0 and -1, $degrees will be returned as
0. If you need to know the sign in these cases, you can use this
longer version, where $sign is 1, 0, or -1 depending on whether
$decimal_degrees is positive, 0, or negative:

  ($degrees, $minutes, $sign) = decimal2dm($decimal_degrees);

=item dec2dm($decimal_degrees)

An alias for decimal2dm().

=item dms2decimal($degrees, $minutes, $seconds)

Converts degrees, minutes, and seconds to the equivalent number of
decimal degrees:

  $decimal_degrees = dms2decimal($degrees, $minutes, $seconds);

If $degrees is negative, then $decimal_degrees will also be negative.

=item dms2dec($degrees, $minutes, $seconds)

An alias for dms2decimal().

=item dm2decimal($degrees, $minutes)

Converts degrees and minutes to the equivalent number of
decimal degrees:

  $decimal_degrees = dm2decimal($degrees, $minutes);

If $degrees is negative, then $decimal_degrees will also be negative.

=item dm2dec($degrees, $minutes)

An alias for dm2decimal().

=back

=head1 CAVEATS

The functions don't do any sanity checks on their arguments.  If you
have a good reason to convert 61 minutes -101 seconds to decimal, go
right ahead.

=head1 AUTHOR

Walt Mankowski, E<lt>waltman@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2024 by Walt Mankowski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS

Thanks to Andy Lester for telling me about pod.t

Thanks to Paulie Pena IV for pointing out that I could remove a
division in decimal2dms().

Thanks to Tim Flohrer for reporting the bug in decimal2dms() and
decimal2dm() when $decimal_degrees is between 0 and -1.

=cut
