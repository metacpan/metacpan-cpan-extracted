package Geo::Lookup::ByTime;

use warnings;
use strict;
use Carp;
use Scalar::Util qw(blessed);
use base qw(Exporter);

our @EXPORT_OK = qw(hav_distance);

our $VERSION = '0.10';

use constant EARTH_RADIUS => 6_378_137.0;
use constant PI           => 4 * atan2( 1, 1 );
use constant DEG_TO_RAD   => PI / 180.0;
use constant RAD_TO_DEG   => 180.0 / PI;

sub new {
    my $class = shift;
    my $self  = {
        points    => [],
        need_sort => 0
    };

    bless( $self, $class );

    if ( @_ ) {
        $self->add_points( @_ );
    }

    return $self;
}

sub add_points {
    my $self = shift;

    $self->{need_sort}++ if @_;

    for my $pt ( @_ ) {
        if (   blessed( $pt )
            && $pt->can( 'latitude' )
            && $pt->can( 'longitude' )
            && $pt->can( 'time' ) ) {
            push @{ $self->{points} },
              {
                lat  => $pt->latitude(),
                lon  => $pt->longitude(),
                time => $pt->time(),
                orig => $pt
              };
        }
        elsif ( ref( $pt ) eq 'CODE' ) {
            my @pts = ();
            while ( my $ipt = $pt->() ) {
                push @pts, $ipt;
                if ( @pts >= 100 ) {
                    # Add points 100 at a time.
                    $self->add_points( @pts );
                    @pts = ();
                }
            }
            $self->add_points( @pts );
        }
        elsif ( ref( $pt ) eq 'ARRAY' ) {
            $self->add_points( @{$pt} );
        }
        elsif ( ref( $pt ) eq 'HASH' ) {
            croak(
                "Point hashes must have the following keys: lat, lon, time\n"
              )
              unless exists( $pt->{lat} )
                  && exists( $pt->{lon} )
                  && exists( $pt->{time} );
            push @{ $self->{points} }, $pt;
        }
        else {
            croak( "Don't know how to add "
                  . ( defined( $pt ) ? $pt : '(undef)' ) );
        }
    }

    return;
}

sub get_points {
    my $self = shift;

    if ( $self->{need_sort} ) {
        my $np = [
            sort { $a->{time} <=> $b->{time} }
              grep {
                     defined( $_->{lat} )
                  && defined( $_->{lon} )
                  && defined( $_->{time} )
              } @{ $self->{points} }
        ];
        $self->{points}    = $np;
        $self->{need_sort} = 0;
    }

    return $self->{points};
}

# Returns the index of the first point with time >= the supplied time
sub _search {
    my $pts  = shift;
    my $time = shift;

    my $max = scalar( @{$pts} );
    my ( $lo, $mid, $hi ) = ( 0, 0, $max - 1 );

    TRY:
    while ( $lo <= $hi ) {
        $mid = int( ( $lo + $hi ) / 2 );
        my $cmp = $pts->[$mid]->{time} <=> $time;
        if ( $cmp < 0 ) {
            $lo = $mid + 1;
        }
        elsif ( $cmp > 0 ) {
            $hi = $mid - 1;
        }
        else {
            last TRY;
        }
    }

    while ( $mid < $max && $pts->[$mid]->{time} < $time ) {
        $mid++;
    }

    return ( $mid < $max ) ? $mid : undef;
}

sub _interp {
    my ( $lo, $mid, $hi, $val1, $val2 ) = @_;
    confess "$lo <= $mid <= $hi !"
      unless $lo <= $mid && $mid <= $hi;
    my $scale = $hi - $lo;
    my $posn  = $mid - $lo;
    return ( $val1 * ( $scale - $posn ) + $val2 * $posn ) / $scale;
}

sub nearest {
    my $self     = shift;
    my $time     = shift;
    my $max_dist = shift;

    my $pts = $self->get_points();
    my $pos = _search( $pts, $time );

    return unless defined( $pos );

    if ( $pts->[$pos]->{time} == $time ) {
        # Exact match - just return the point
        my $pt = {
            lat  => $pts->[$pos]->{lat},
            lon  => $pts->[$pos]->{lon},
            time => $time
        };

        return
          wantarray
          ? ( $pt, $pts->[$pos]->{orig} || $pts->[$pos], 0 )
          : $pt;
    }

    # If we're at the first point we can't
    # interpolate with anything.
    return if $pos == 0;

    my ( $p1, $p2 ) = @$pts[ $pos - 1, $pos ];

    # Linear interpolation between nearest points
    my $lat = _interp( $p1->{time}, $time, $p2->{time}, $p1->{lat},
        $p2->{lat} );
    my $lon = _interp( $p1->{time}, $time, $p2->{time}, $p1->{lon},
        $p2->{lon} );

    my $pt = {
        lat  => $lat,
        lon  => $lon,
        time => $time
    };

    my $best_dist = 0;
    my $best      = undef;

    # Compute nearest if we need to return it or check proximity
    if ( wantarray || defined( $max_dist ) ) {
        my $d1 = abs( $pt->{time} - $p1->{time} );
        my $d2 = abs( $pt->{time} - $p2->{time} );

        $best = ( $d1 < $d2 ) ? $p1 : $p2;
        $best_dist = hav_distance( $pt, $best );

        # Nearest point out of range?
        return if defined( $max_dist ) && $best_dist > $max_dist;
    }

    # Return a synthetic point
    return
      wantarray ? ( $pt, $best->{orig} || $best, $best_dist ) : $pt;
}

sub _deg {
    return map { $_ * RAD_TO_DEG } @_;
}

sub _rad {
    return map { $_ * DEG_TO_RAD } @_;
}

# From
#  http://perldoc.perl.org/functions/sin.html
sub _asin {
    return atan2( $_[0], sqrt( 1 - $_[0] * $_[0] ) );
}

# Not a method
sub hav_distance {
    my $dist = 0;
    my ( $lat1, $lon1 );
    while ( my $pt = shift ) {
        my ( $lat2, $lon2 ) = _rad( $pt->{lat}, $pt->{lon} );
        if ( defined( $lat1 ) ) {
            my $sdlat = sin( ( $lat1 - $lat2 ) / 2.0 );
            my $sdlon = sin( ( $lon1 - $lon2 ) / 2.0 );
            my $res = sqrt( $sdlat * $sdlat
                  + cos( $lat1 ) * cos( $lat2 ) * $sdlon * $sdlon );
            if ( $res > 1.0 ) {
                $res = 1.0;
            }
            elsif ( $res < -1.0 ) {
                $res = -1.0;
            }
            $dist += 2.0 * _asin( $res );
        }
        ( $lat1, $lon1 ) = ( $lat2, $lon2 );
    }

    return $dist * EARTH_RADIUS;
}

sub time_range {
    my $self = shift;
    my $pts  = $self->get_points();
    return unless @{$pts};
    return ( $pts->[0]->{time}, $pts->[-1]->{time} );
}

1;
__END__

=head1 NAME

Geo::Lookup::ByTime - Lookup location by time

=head1 VERSION

This document describes Geo::Lookup::ByTime version 0.10

=head1 SYNOPSIS

    use Geo::Lookup::ByTime;
    
    $lookup = Geo::Lookup::ByTime->new( @points );
    my $pt = $lookup->nearest( $tm );

=head1 DESCRIPTION

Given a set of timestamped locations guess the location at a particular
time. This is a useful operation for, e.g., adding location information
to pictures based on their timestamp and a GPS trace that covers the
same time period.

=head1 INTERFACE 

=over

=item C<new( [ points ] )>

Create a new object optionally supplying a list of points. The points
may be supplied as an array or as a reference to an array. Each point
may be a reference to a hash containing at least the keys C<lat>, C<lon>
and C<time> or a reference to an object that supports accessor methods
called C<latitude>, C<longitude> and C<time>. 

If a coderef is supplied it is assumed to be an iterator that may be
called repeatedly to yield a set of points.

=item C<add_points( [ points ] )>

Add points. The specification for what constitutes a point is the same
as for C<new>.

=item C<nearest( $time [ , $max_dist ] )>

Return a hash indicating the estimated position at the specified time.
The returned hash has C<lat>, C<lon> and C<time> keys like this:

    my $best = {
        lat     => 54.29344,
        lon     => -2.02393,
        time    => $time
    };

Returns C<undef> if the position can't be computed. By default a
position will be calculated for any point that lies within the range of
time covered by the reference points. Optionally C<$max_dist> may
be specified in which case C<undef> will be returned if the closest
real point is more than that many metres away from the computed point.

If the requested time coincides exactly with the timestamp of one
of the points the returned point will be at the same location as
the matching point. If the time falls between the timestamps of
two points the returned point will be linearly interpolated from
those two points.

In an array context returns a list containing the synthetic point
at the specified time (i.e. the value that would be returned in
scalar context), the closest real point and the distance between
the two in metres

    my ($best, $nearest, $dist) = $lookup->nearest( $tm );

=item C<get_points()>

Return a reference to an array containing all the points in ascending
time order.

=item C<time_range()>

Return as a two element list the time range from earliest to latest of
the points in the index. Returns C<undef> if the index is empty.

=item C<hav_distance($pt, ...)>

Exportable function. Computes the Haversine distance in metres along the
line described by the points passed in. Points must be references to hashes
with keys C<lat> and C<lon>.

=back

=head1 DIAGNOSTICS

=over

=item C<< Point hashes must have the following keys: lat, lon, time >>

You attempted to add as a point a hash that didn't have the necessary
keys. Each point must have at least C<lat>, C<lon> and C<time>.

=item C<< Don't know how to add %s >>

Points can be added by supplying a list of objects that behave like
points (i.e. have accessors called C<latitude>, C<longitude> and
C<time>), references to hashes with the keys C<lat>, C<lon> and C<time>,
iterators that return a stream of point like objects or arrays of any of
the above. You tried to add something other than one of those.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-geo-lookup-bytime@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
