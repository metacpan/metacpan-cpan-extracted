package Geo::TCX::Track;
use strict;
use warnings;

our $VERSION = '1.03';

=encoding utf-8

=head1 NAME

Geo::TCX::Track - Class to store and edit a TCX track and its trackpoints

=head1 SYNOPSIS

  use Geo::TCX::Track;

=head1 DESCRIPTION

This package is mainly used by the L<Geo::TCX> module and serves little purpose on its own. The interface is documented mostly for the purpose of code maintainance.

L<Geo::TCX::Track> provides a data structure for tracks in TCX files as well as methods to store, edit and obtain information from its trackpoints.

=cut

use Geo::TCX::Trackpoint;
use Carp qw(confess croak cluck);
use Data::Dumper;
use overload '+' => \&merge;

=head2 Constructor Methods (class)

=over 4

=item new( xml_string )

takes an I<xml_string> in the form recorded by Garmin devices (and its TCX format) and returns a track object composed of various L<Geo::TCX::Trackpoint> objects.

The string argument is expected to be flat i.e. no line breaks as per the example below.

  $xml_string = '<Track><Trackpoint><Time>2014-08-11T10:25:23Z</Time><Position><LatitudeDegrees>45.305054</LatitudeDegrees><LongitudeDegrees>-72.637287</LongitudeDegrees></Position><AltitudeMeters>210.963</AltitudeMeters><DistanceMeters>5.704</DistanceMeters><HeartRateBpm><Value>75</Value></HeartRateBpm></Trackpoint></Track>';

  $t = Geo::TCX::Track->new( $xml_string );

=back

=cut

sub new {
    my ($proto, $track_str, $previous_pt) = (shift, shift, shift);
    if (ref $previous_pt) {
        croak 'second argument must be a Trackpoint object' unless $previous_pt->isa('Geo::TCX::Trackpoint')
    }
    croak 'new() takes only one or two arguments' if @_;
    my $class = ref($proto) || $proto;
    my ($chomped_str, $t);
    if ( $track_str =~ m,\s*^\<Track\>(.*)\</Track\>\s*$,gs ) {
        $chomped_str = $1
    } else { croak 'not a proper track string' }

    $t = {};
    $t->{Points} = [];

    while ($chomped_str=~ m,(\<Trackpoint\>.*?\</Trackpoint\>),gs) {
        my $pt = Geo::TCX::Trackpoint::Full->new($1, $previous_pt);
        $previous_pt = $pt;
        push @{$t->{Points}}, $pt
    }
    bless($t, $class);
    return $t
}

=head2 Constructor Methods (object)

=over 4

=item merge( $track, as_is => boolean, speed => value )

Returns a new merged with the track specified in I<$track>.

  $merged = $track1->merge( $track2 );

Adjustments for the C<DistanceMeters> and C<Time> fields of each trackpoint in the track are made unless C<as_is> is set to true.

If a I<value> is passed to field C<speed>, that value will be used to ajust the time elapsed between the first point of the I<$track> and the last point of the track to be merged with. Otherwise the speed will be estimated based on the total distance and time elapsed of all the trackpoints in the I<$track>. C<speed> has not effect if C<as_is> is true.

=back

=cut

sub merge {
    my ($x, $y) = (shift, shift);
    croak 'both operands must be Track objects' unless $y->isa('Geo::TCX::Track');
    $x = $x->clone;
    $y = $y->clone;
    my %opts = @_;      # option are as_is => boole and speed => value

    unless ($opts{as_is}) {
        $opts{tolerance} ||= 50;

        my ($gap, $msg);
        $gap = $x->trackpoint(-1)->distance_to( $y->trackpoint(1) );
        $msg = 'distance between the two tracks to merge is ' . $gap .  ' meters, which '
              . 'is larger than the tolerance of ' . $opts{tolerance} . ' meters';
        croak $msg if $gap > $opts{tolerance};

        #
        # Distance: adjust DistanceMeters of all trackpoints, elapsed of just the 1st one
        my $dist_to_add;
        $dist_to_add  = $x->trackpoint(-1)->DistanceMeters + $gap - $y->trackpoint(1)->distance_elapsed;

        $y->distance_net;
        $y->distance_add( $dist_to_add );

        $y->trackpoint(1)->distance_elapsed( $gap, force => 1);

        #
        # Time: adjust Time of all trackpoints, elapsed of just the 1st one

        my ($duration, $speed, $elapsed_t);
        $duration = $y->trackpoint(1)->time_duration( $x->trackpoint(-1) );
        $speed = $opts{speed} ? $opts{speed} : $y->_speed_meters_per_second;
        $elapsed_t = sprintf '%.0f', $gap / $speed;

        $y->time_subtract( $duration );
        $y->time_add( DateTime::Duration->new( seconds => $elapsed_t ));

        $y->trackpoint(1)->time_elapsed($elapsed_t, force => 1);


        # my $epoch_gap = $x->trackpoint(-1)->time_epoch + $delay;
        # my $delta_epoch = $epoch_gap - $y->trackpoint(1)->time_epoch;
        #
        # my $delta_dist = $x->trackpoint(1)->DistanceMeters;
        # adjust DistanceMeters of x points, netting to 0 at point 1

        # now applying both the distance netting and delta_epoch to each y point
        # for my $pt (@{$y->{Points}}) {
        #     my $epoch = $pt->time_epoch;
        #     $epoch += $delta_epoch;
        #     $pt->time_epoch( $epoch );
        #     $pt->DistanceMeters( $pt->DistanceMeters - $delta_dist );
        #     push @{$x->{Points}}, $pt
    }

    my @points_to_merge = @{$y->{Points}};
    for my $pt (@points_to_merge) {
        push @{$x->{Points}}, $pt
    }
    return $x
}

=over 4

=item split( # )

Returns a 2-element array of C<Geo::TCX::Track> objects with the first consisting of the track up to and including point number I<#> and the second consisting of the all trackpoints after that point.

  ($track1, $track2) = $merged->split( 45 );

Will raise exception unless called in list context.


=back

=cut

sub split {
    my ($t, $pt_no) = @_;
    croak 'split() expects to be called in list context' unless wantarray;
    my $n_pts = $t->trackpoints;
    my ($t1, $t2) = ($t->clone, $t->clone);
    my @slice1 =   @ { $t1->{Points} } [0 .. $pt_no - 1];
    my @slice2 =   @ { $t1->{Points} } [$pt_no .. $n_pts- 1];
    $t1->{Points} = \@slice1;
    $t2->{Points} = \@slice2;
    return $t1, $t2
}

# keep undocumented for now, serves little purpose unless Lap.pm would want to call it directly, which it does not at this time.

# =over 4
# 
# =item split_at_point_closest_to( $point or $trackpoint or $coord_str )
# 
# Equivalent to C<split()> but splits at the trackpoint that lies closest to a given L<Geo::Gpx::Point>, L<Geo::TCX::Trackpoint>,  or a string that can be interpreted as coordinates by C<< Geo::Gpx::Point->flex_coordinates >>.
# 
# =back
# 
# =cut

sub split_at_point_closest_to {
    my ($t, $to_pt) = (shift, shift);
    croak 'split() expects to be called in list context' unless wantarray;
    croak 'split_at_point_closest_to() expects a single argument' if ! defined $to_pt or @_;
    # can leverage most of the checks that will be done by point_closest_to
    $to_pt = Geo::Gpx::Point->flex_coordinates( \$to_pt ) unless ref $to_pt;
    my ($closest_pt, $min_dist, $pt_no) = $t->point_closest_to( $to_pt );
    # here we can print some info about the original track and where it will be split
    my ($t1, $t2) = $t->split( $pt_no );
    return $t1, $t2
}

=over 4

=item reverse()

Returns a clone of a track with the order of the trackpoints reversed.

  $reversed = $track->reverse;

=back

=cut

sub reverse {
    my $orig_t = shift;
    my $t = $orig_t->clone;
    my $n_points = $t->trackpoints;
    $t->{Points} = [];
    my ($previous_pt, $previous_pt_orig);

    for my $i (1 .. $n_points) {
        my $pt = $orig_t->trackpoint($n_points - $i + 1)->clone;

        if ($i == 1) {
            $pt->_reset_distance( 0 );
            $pt->_reset_time( $orig_t->trackpoint(1)->Time )
        } else {
            $pt->_reset_distance( $previous_pt->DistanceMeters + $previous_pt_orig->distance_elapsed, $previous_pt );
            $pt->_reset_time_from_epoch( $previous_pt->time_epoch + $previous_pt_orig->time_elapsed,  $previous_pt)
        }

        $previous_pt = $pt;
        $previous_pt_orig = $orig_t->trackpoint($n_points - $i + 1)->clone;
        # need copy of the original previous pt bcs elapsed fields of $pt got updated above
        push @{$t->{Points}}, $pt
    }
    return $t
}

=over 4

=item clone()

Returns a deep copy of a C<Geo::TCX::Track> instance.

  $c = $track->clone;

=back

=cut

sub clone {
    my $clone;
    eval(Data::Dumper->Dump([ shift ], ['$clone']));
    confess $@ if $@;
    return $clone
}

=head2 Object Methods

=over 4

=item trackpoint( # )

returns the trackpoint object corresponding to trackpoint number I<#> for the track.

I<#> is 1-indexed but C<-1>, C<-2>, …, still refer to the last, second to last, …, points respectively.

=back

=cut

sub trackpoint {
    my ($t, $point_i) = (shift, shift);
    croak 'trackpoints are 1-indexed, point 0 does not exist' if $point_i eq 0;
    croak 'requires a single integer as argument' if ! $point_i or @_;
    $point_i-- if $point_i > 0;   # 1-indexed but want -1 to still refer to last
    return $t->{Points}[$point_i]
}

=over 4

=item trackpoints( qw/ # # ... / )

returns an array of L<Geo::TCX::Trackpoint> objects for the number of points specified in list if specified, or all trackpoints if called without arguments.

=back

=cut

sub trackpoints {
    my ($t, @point_list) = @_;
    my $points = $t->{Points};
    my @points;
    if (@point_list) {
        map --$_, @point_list;    # decrement to get array indices
        @points = @$points[@point_list];
    } else { @points = @$points }
    return @points
}

=over 4

=item distance_add( $meters )

=item distance_subtract( $meters )

=item distance_net()

Add or subtract to the DistanceMeters field of all points in a Track. Does not impact any other fields of trackpoints. Return true.

C<distance_net> is equivalent to C<< $t->distance_subtract( $t->trackpoint(1)->DistanceMeters - $t->trackpoint(1)->distance_elapsed ) >>.

=back

=cut

sub distance_add {
    my ($t, $meters) = (shift, shift);
    for my $i (0 .. $#{$t->{Points}}) {
        my $tp = $t->{Points}[$i];
        $tp->_set_distance_keys( $tp->DistanceMeters + $meters )
    }
    return 1
}

sub distance_subtract {
    my ($t, $meters) = (shift, shift);
    $t->distance_add( - $meters );
    return 1
}

sub distance_net {
    my $t = shift;
    my $tp1 = $t->trackpoint(1);
    $t->distance_subtract( $tp1->DistanceMeters - $tp1->distance_elapsed );
    return 1
}

=over 4

=item time_add( @duration )

=item time_subtract( @duration )

Perform L<DateTime> math on the timestamps of each trackpoint in the track by adding or subtracting the specified duration. Return true.

The duration can be provided as an actual L<DateTime::Duration> object or an array of arguments as per the syntax of L<DateTime>'s C<add()> or C<subtract()> methods. See the pod for C<< Geo::TCX::Trackpoint->time_add() >>.

=back

=cut

sub time_add {
    my $t = shift;
    if (ref $_[0] and $_[0]->isa('DateTime::Duration') ) {
        my $dur = shift;
        $t->{Points}[$_]->time_add($dur) for (0 .. $#{$t->{Points}})
    } else {
        my @dur= @_;
        $t->{Points}[$_]->time_add(@dur) for (0 .. $#{$t->{Points}})
    }
    return 1
}

sub time_subtract {
    my $t = shift;
    if (ref $_[0] and $_[0]->isa('DateTime::Duration') ) {
        my $dur = shift;
        $t->{Points}[$_]->time_subtract($dur) for (0 .. $#{$t->{Points}})
    } else {
        my @dur= @_;
        $t->{Points}[$_]->time_subtract(@dur) for (0 .. $#{$t->{Points}})
    }
    return 1
}

=over 4

=item point_closest_to( $point or $trackpoint )

Takes any L<Geo::Gpx::Point> or L<Geo::TCX::Trackpoint> and returns the trackpoint that is closest to it on the track.

If called in list context, returns a three element array consisting of the trackpoint, the distance from the coordinate to the trackpoint (in meters), and the point number of that trackpoint in the track.

=back

=cut

# ::Lap calls it by inheritance from Geo::TCX's split_at_point_closest_to()

sub point_closest_to {
    my ($t, $to_pt) = (shift, shift);
    croak 'closest_to() expects a single argument' if @_;
    my $class = ref( $to_pt );
    unless ($class->isa('Geo::TCX::Trackpoint') or $class->isa('Geo::Gpx::Point')) {
        croak 'point_closest_to() expects a Geo::TCX::Trackpoint of Geo::Gpx::Point as argument'
    }

    my $gc = $to_pt->to_geocalc;
    my ($closest_pt, $min_dist, $pt_no);
    for (0 .. $#{$t->{Points}}) {
        my $pt   = $t->{Points}[$_];
        my $lat = $pt->LatitudeDegrees;
        my $lon = $pt->LongitudeDegrees;
        if (!$lat or !$lon) {
            print "point number ", ($_ + 1), " doesn't have coordinates\n";
            next
        }
        my $distance = $gc->distance_to({ lat => $lat, lon => $lon });
        $min_dist ||= $distance; # the first iteration
        $closest_pt ||= $pt; # the first iteration
        if ($distance < $min_dist) {
            $closest_pt = $pt;
            $min_dist   = $distance;
            $pt_no = $_ + 1
        }
    }
    return ($closest_pt, $min_dist, $pt_no) if wantarray;
    return $closest_pt
}

=over 4

=item xml_string( # )

returns a string containing the XML representation of the object, equivalent to the string argument expected by C<new()>.

=back

=cut

sub xml_string {
    my $t = shift;
    my %opts = @_;

    my $newline = $opts{indent} ? "\n" : '';
    my $tab     = $opts{indent} ? '  ' : '';
    my $n_tabs  = $opts{n_tabs} ? $opts{n_tabs} : 3;

    my $str .= $newline . $tab x $n_tabs . '<Track>';
    # here, create a accessor that lists how many points there are in the track and do for my $i (1.. # of trackpoints)
    for my $pt (@{$t->{Points}}) {
# looks like I coded this to ignore points without a Position as point 2014-08-11T10:25:40Z
# look into this
# next unless ($pt->LatitudeDegrees);
        $str .= $pt->xml_string( indent => $opts{indent}, n_tabs => ($n_tabs + 1) )
    }
    $str .= $newline . $tab x $n_tabs . '</Track>';
    return $str
}

=over 4

=item summ()

For debugging purposes, summarizes the fields of the track by printing them to screen. Returns true.

=back

=cut

sub summ {
    my $t = shift;
    croak 'summ() expects no arguments' if @_;
    my %fields;
    foreach my $key (keys %{$t}) {
        print "$key: ", $t->{$key}, "\n"
    }
    return 1
}

=head2 Overloaded Methods

=over 4

=item +

merge two tracks by calling C<$track = $track1 + $track2>.

=back

=cut

#
# internal methods

sub _speed_meters_per_second {
    my $t = shift;
    my ($distance, $speed);
    $distance = $t->trackpoint(-1)->DistanceMeters - $t->trackpoint(1)->DistanceMeters +  $t->trackpoint(1)->distance_elapsed;
    $speed = $distance / $t->_totalseconds;
    return $speed
}

sub _totalseconds {
    my ($t, $totalseconds) = (shift, 0);
    $totalseconds += $t->trackpoint($_)->time_elapsed for (1 .. $t->trackpoints);
    return $totalseconds
}

=head1 EXAMPLES

Coming soon.

=head1 AUTHOR

Patrick Joly

=head1 VERSION

1.03

=head1 SEE ALSO

perl(1).

=cut

1;

