package Geo::Compass::Direction;

use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use Exporter qw(import);

our $VERSION = '1.00';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(direction);

my @DIRECTIONS = qw(
    N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW N
);

sub direction {
    my ($deg) = @_;

    if (! defined $deg) {
        croak("direction() must have an integer or float as its only parameter");
    }
    if ($deg !~ /^\d+$/ && $deg !~ /^\d+\.\d+$/) {
        croak("The degree parameter for direction() must be an int or float");
    }
    if ($deg < 0 || $deg > 360) {
        croak("The degree parameter must be an int or float between 0-360");
    }

    my $calc = (($deg % 360) / 22.5) + .5;

    return $DIRECTIONS[$calc];
}
sub __placeholder {}

1;
__END__

=head1 NAME

Geo::Compass::Direction - Convert a compass heading degree into human readable
direction

=for html
<a href="http://travis-ci.com/stevieb9/geo-compass-direction"><img src="https://www.travis-ci.com/stevieb9/geo-compass-direction.svg?branch=master"/>
<a href='https://coveralls.io/github/stevieb9/geo-compass-direction?branch=master'><img src='https://coveralls.io/repos/stevieb9/geo-compass-direction/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Geo::Compass::Direction qw(direction);

    my $dir;

    $dir = direction(0);              # N
    $dir = direction(327);            # NNW
    $dir = direction(180.235323411);  # S

=head1 DESCRIPTION

Converts a compass heading degree into human readable direction
(eg: C<N>, C<SSW>)

=head1 EXPORT_OK

This module exports only a single function, C<<direction()>>, and it must
be imported explicitly.

=head1 FUNCTIONS

=head2 direction($degree)

Convert a compass heading degree into human readable format.

Parameters:

    $degree

Mandatory, Int|Float: The compass degree to use for the conversion. Can be an
integer (eg C<360>) or a float (eg C<179.12352211>).

Returns: String. The letter designation of the heading.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

