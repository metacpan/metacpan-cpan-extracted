package Geo::Coder::Many::Util;

use strict;
use warnings;
use Geo::Distance::XS; # for calculating precision
use List::Util qw( reduce );
use List::MoreUtils qw( any );

our @EXPORT_OK = qw( 
    min_precision_filter 
    max_precision_picker 
    consensus_picker 
    country_filter 
);
use Exporter;
use base qw(Exporter);

our $VERSION = '0.01';

my $GDXS = Geo::Distance->new;

=head1 NAME

Geo::Coder::Many::Util

=head1 DESCRIPTION

Miscellaneous routines that are convenient for, for example, generating
commonly used callback methods to be used with Geo::Coder::Many.

=head1 SUBROUTINES

=head2 min_precision_filter

Constructs a result filter callback which only passes results which exceed the
specified precision.

=cut

sub min_precision_filter {
    my $precision_cutoff = shift;
    return sub {
        my $result = shift;
        if ( !defined $result->{precision} ) {
            return 0;
        }
        return $result->{precision} >= $precision_cutoff;
    }
}

=head2 country_filter

Constructs a result filter callback which only passes results with the
specified 'country' value.

=cut

sub country_filter {
    my $country_name = shift;
    return sub {
        my $result = shift;
        if ( !exists $result->{country} ) {
            return 0;
        }
        return $result->{country} eq $country_name;
    }
}

=head2 max_precision_picker

A picker callback that requests all available results, and then picks the one
with the highest precision. Note that querying all available geocoders may take
a comparatively long time.

Example:

$GCMU->set_picker_callback( \&max_precision_picker );

=cut

sub max_precision_picker {
    my ($ra_results, $more_available) = @_;

    # If more results are available, request them
    return if $more_available;

    # If we have all of the results, find the best
    return &_find_max_precision($ra_results);
}

=head2 consensus_picker 

Returns a picker callback that requires at least 'required_consensus' separate
geocoder results to be within a bounding square of side-length 'nearness'. If
this can be satisfied, the result from that square which has the highest
precision will be returned. Otherwise, asks for more/returns undef. 

WARNING: quadratic time in length of @$ra_results - could be improved if
necessary.

Example:

$GCMU->set_picker_callback( 
    consensus_picker({nearness => 0.1, required_consensus => 2})
);

=cut

sub consensus_picker {
    my $rh_args = shift;
    my $nearness = $rh_args->{nearness};
    my $required_consensus = $rh_args->{required_consensus};
    return sub {
        my $ra_results = shift;

        for my $result_a (@{$ra_results}) {

            my $lat_a = $result_a->{latitude};
            my $lon_a = $result_a->{longitude};

            # Find all of the other results that are close to this one
            my @consensus = grep { 
                _in_box( 
                    $lat_a, 
                    $lon_a, 
                    $nearness, 
                    $_->{latitude}, 
                    $_->{longitude} 
                ) 
            } @$ra_results;

            if ($required_consensus <= @consensus) {
                # If the consensus is sufficiently large, return the result
                # with the highest precision
                return _find_max_precision(\@consensus);
            }

        }

        # No consensus reached
        return;
    };
}

=head2 determine_precision_from_bbox

    my $precision = Geo::Coder::Many::Util->determine_precision_from_bbox({
                       'lon1' => $sw_lon,
                       'lat1' => $sw_lat,
                       'lon2' => $ne_lon,
                       'lat2' => $ne_lat,
                    });

returns a precison between 0 (unknown) and 1 (highly precise) based on 
the size of the box supplied

=cut

sub determine_precision_from_bbox {
    my $rh_args = shift || return 0;

    my $distance = $GDXS->distance('kilometer', 
                                $rh_args->{lon1}, $rh_args->{lat1} => 
                                $rh_args->{lon2}, $rh_args->{lat2});

    return 0    if (!defined($distance));
    return 1.0  if ($distance <  0.25);
    return 0.9  if ($distance <  0.5);
    return 0.8  if ($distance <  1);
    return 0.7  if ($distance <  5);
    return 0.6  if ($distance <  7.5);
    return 0.5  if ($distance < 10);
    return 0.4  if ($distance < 15);
    return 0.3  if ($distance < 20);
    return 0.2  if ($distance < 25);
    return 0.1;  
}

=head1 INTERNAL ROUTINES

=head2 _in_box

Used by consensus_picker - returns true if ($lat, $lon) is inside the square
with centre ($centre_lat, $centre_lon) and side length 2*$half_width.

=cut

sub _in_box {
    my ($centre_lat, $centre_lon, $half_width, $lat, $lon) = @_;

    return $centre_lat - $half_width < $lat
        && $centre_lat + $half_width > $lat
        && $centre_lon - $half_width < $lon
        && $centre_lon + $half_width > $lon;
}

=head2 _find_max_precision

Given a reference to an array of result hashes, returns the one with the
highest precision value

=cut

sub _find_max_precision {
    my $ra_results = shift;
    return reduce {
        ($a->{precision} || 0.0) > ($b->{precision} || 0.0) ? $a : $b 
    } @{$ra_results};
}

1;
