package Geo::TCX::Lap;
use strict;
use warnings;

our $VERSION = '1.04';
our @ISA=qw(Geo::TCX::Track);

=encoding utf-8

=head1 NAME

Geo::TCX::Lap - Extract and edit info from Lap data

=head1 SYNOPSIS

  use Geo::TCX::Lap;

=head1 DESCRIPTION

This package is mainly used by the L<Geo::TCX> module and serves little purpose on its own. The interface is documented mostly for the purpose of code maintainance.

A sub-class of L<Geo::TCX::Track>, it enables extracting and editing lap information associated with tracks contained in Garmin TCX files. Laps are a more specific form of a Track in that may contain additional information such as lap aggregates (e.g. TotalTimeSeconds, DistanceMeters, …), performance metrics (e.g. MaximumSpeed, AverageHeartRateBpm, …), and other useful fields.

The are two types of C<Geo::TCX::Lap>: Activity and Courses.

=over 4

=item Activity

Activity laps are tracks recorded by the Garmin from one of the activity types ('Biking', 'Running', 'MultiSport', 'Other') and saved in what is often refered to ashistory files.

=item Course

Course laps typically originate from history files that are converted to a course either by a Garmin device or some other software for the purpose of navigation or training. They contain course-specific fields such as C<BeginPosition> and C<EndPosition> and some lap aggregagates but do not contain the performance-metrics or other fields that acivity laps contain.

=back

See the AUTOLOAD section for a list of all supported fields for each type of lap.

Some methods and accessors are applicable only to one type. This is specified in the documentation for each.

=cut

use Carp qw(confess croak cluck);
use Geo::TCX::Track;
use overload '+' => \&merge;
use vars qw($AUTOLOAD %possible_attr);

# file-scoped lexicals
my @attr = qw/ AverageHeartRateBpm Cadence Calories DistanceMeters Intensity MaximumHeartRateBpm MaximumSpeed TotalTimeSeconds TriggerMethod StartTime BeginPosition EndPosition/;
$possible_attr{$_} = 1 for @attr;
# last 2 are specific to courses only
# no Track tag, wouldn't make sense to AUTOLOAD it

=head2 Constructor Methods (class)

=over 4

=item new( $xml_string, $lapno )

parses and xml string in the form of the lap portion from a Garmin Activity or Course and returns a C<Geo::TCX::Lap> object.

No examples are provided as this constructor is typically called by instances of L<Geo::TCX>. The latter then provides various methods to access lap data and info. The I<$lapno> (lap number) is optional.

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($str, $lapnumber, $last_point_previous_lap) = (shift, shift, shift);
    if (ref $last_point_previous_lap) {
        croak 'second argument must be a Trackpoint object'
            unless $last_point_previous_lap->isa('Geo::TCX::Trackpoint')
    }
    my %opts = @_;      # none for now, but setting it up

    my ($type, $starttime, $metrics, $metrics_and_track, $track_str);
    if ( $str =~ /\<Lap StartTime="(.*?)"\>(.*?)\<\/Lap\>/s ) {
        $type = 'Activity';
        $starttime = $1;
        $metrics_and_track = $2;
        if ( $metrics_and_track =~ /(.*?)(\<Track\>.*\<\/Track\>)/s ) {
            $metrics = $1;
            $track_str = $2
        }
    } elsif ( $str =~ /\<Lap\>(.*?)\<\/Lap\>(.*)/s ) {
        $type = 'Course';
        $metrics = $1;
        $track_str = $2
    } else { croak 'string argument not in a format supported' }
    croak 'No track data found in lap' unless $track_str;

    # First, create the track object from the super-class

    my $l = $class->SUPER::new( $track_str, $last_point_previous_lap );
    bless($l, $class);

    if ($type eq 'Activity') {
        $l->{_type} = 'Activity';
        $l->{StartTime} = $starttime;

        $l->_process_remaining_lap_metrics( \$metrics );

        # Lap is smarter than Track:
        #   it knows that its StartTime may be ahead of the time of the first trackpoint
        #   so force a replace of the elapsed time with that time difference

        # StartTime is not a trackpoint, but we can create a fake one so we can
        # get an trackpoint object that allows us to get the epoch time from it
        my $fake = _fake_starttime_point( $l->{StartTime} );
        my $time_elapsed = $l->trackpoint(1)->time_epoch - $fake->time_epoch;
        $l->trackpoint(1)->time_elapsed( $time_elapsed, force => 1)
    }
    if ($type eq 'Course') {
        $l->{_type} = 'Course';

        # Lap is again smarter than Track:
        #   but instead of knowing *when* it started (as for activities), it knows *where*
        #   nb: courses converted by save_laps() and Ride with GPS always have the BeginPosition
        #   equal to the first trackpoint.

        if ( $metrics =~ s,\<BeginPosition\>(.*)\</BeginPosition\>,,g) {
            $l->{BeginPosition} = Geo::TCX::Trackpoint->new( $1 )
        }
        if ( $metrics =~ s,\<EndPosition\>(.*)\</EndPosition\>,,g) {
            $l->{EndPosition} = Geo::TCX::Trackpoint->new( $1 )
        }

        $l->_process_remaining_lap_metrics( \$metrics );

        my ($meters, $time_elapsed) = (undef, 0);
        # can compare if $meters is almost identical to $l->trackpoint(1)->DistanceMeters;
        # we could simply have used the later to estimate the time elapsed but it is nice
        # to check from the BeginPosition
        $meters = $l->{BeginPosition}->distance_to( $l->trackpoint(1) );
        if ($meters > 0) {
            my $avg_speed = $l->_avg_speed_meters_per_second;
            $time_elapsed = sprintf( '%.0f', $meters / $avg_speed );
        }
        $l->trackpoint(1)->time_elapsed( $time_elapsed, force => 1 )
    }

    $l->{_lapmetrics} = $metrics;  # delete this ine once I am sure that I capture all metrics and track info properly

    # estimate auto-pause time for use by split()
    $l->{_time_auto_paused} = sprintf( '%.2f', $l->totaltimeseconds - $l->TotalTimeSeconds);
    return $l
}

=head2 Constructor Methods (object)

=over 4

=item merge( $lap, as_is => boolean )

Returns a new C<Geo::TCX::Lap> merged with the lap specified in I<$lap>.

  $merged = $lap1->merge( $lap2 );

Adjustments for the C<DistanceMeters> and C<Time> fields of each trackpoint in the lap are made unless C<as_is> is set to true.

Lap aggregates C<TotalTimeSeconds> and C<DistanceMeters> are adjusted. For Activity laps, performance metrics such as C<MaximumSpeed>, C<AverageHeartRateBpm>, …, are also adjusted. For Course laps, C<EndPosition> is also adjusted. 

Unlike the C<merge_laps()> method in L<Geo::TCX>, the laps do not need to originate from the same *.tcx file, hence there is also no requirement that they be consecutive laps as is the case in the former.

=back

=cut

sub merge {
    my ($x, $y) = (shift, shift);
    croak 'both operands must be Lap objects' unless $y->isa('Geo::TCX::Lap');
    my %opts = @_;

    my $m = $x->SUPER::merge($y, speed => $y->_avg_speed_meters_per_second, as_is => $opts{'as_is'});

    $m->{DistanceMeters}    =  $m->DistanceMeters + $y->DistanceMeters;
    $m->{_time_auto_paused} =  sprintf('%.2f', $m->{_time_auto_paused} + $y->{_time_auto_paused});

    if ($opts{as_is}) {             # then do not adjust TTS, just summ them up
        $m->{TotalTimeSeconds} = sprintf('%.2f', $m->TotalTimeSeconds + $y->TotalTimeSeconds)
    } else {
        # i.e. if the 2nd lap did not come from the same ride, we will have estimated the elapsed time bewteen the two tracks
        $m->{TotalTimeSeconds} = sprintf('%.2f', $m->totaltimeseconds - $m->{_time_auto_paused})
    }

    if ($m->is_activity) {              # aggregates specific to activities
        my $pcent = $y->TotalTimeSeconds / $m->TotalTimeSeconds;

        # max values
        if (defined $m->MaximumSpeed) {
            if (defined $y->MaximumSpeed) {
                $m->{MaximumSpeed} = ($m->MaximumSpeed > $y->MaximumSpeed) ? $m->MaximumSpeed : $y->MaximumSpeed
            } else { $m->{MaximumSpeed} = undef }
        }
        if (defined $m->MaximumHeartRateBpm) {
            if (defined $y->MaximumHeartRateBpm) {
                $m->{MaximumHeartRateBpm} = ($m->MaximumHeartRateBpm > $y->MaximumHeartRateBpm) ? $m->MaximumHeartRateBpm : $y->MaximumHeartRateBpm
            } else { $m->{MaximumHeartRateBpm} = undef }
        }

        # average values
        if (defined $m->AverageHeartRateBpm) {
            if (defined $y->AverageHeartRateBpm) {
                $m->{AverageHeartRateBpm} = sprintf '%.0f', ( (1 - $pcent) * $m->AverageHeartRateBpm + $pcent * $y->AverageHeartRateBpm )
            } else { $m->{AverageHeartRateBpm} = undef }
        }
        if (defined $m->Cadence) {
            if (defined $y->Cadence) {
                $m->{Cadence} = sprintf '%.0f', ( (1 - $pcent) * $m->Cadence + $pcent * $y->Cadence )
            } else { $m->{Cadence} = undef }
        }

        # summed values
        if (defined $m->Calories) {
            if (defined $y->Calories) {
                $m->{Calories} = $m->Calories + $y->Calories
            } else { $m->{Calories} = undef }
        }

        # keep values of first lap for other attr: Intensity, TriggerMethod, and StartTime
        #   Intensity: I have never seen another setting than Active
        #   TriggerMethod: I consider that one barely relevant

    } else {                            # aggregates specific to courses
        $m->{EndPosition} =  $y->trackpoint(-1)->to_basic
    }
    return $m
}

=over 4

=item split( # )

Returns a 2-element array of C<Geo::TCX::Lap> objects with the first consisting of the lap up to and including point number I<#> and the second consisting of the all trackpoints after that point.

  ($lap1, $lap2) = $merged->split( 45 );

Lap aggregates C<TotalTimeSeconds> and C<DistanceMeters> are recalculated, some small measurement error is to be expected due to the amount of time the device was an auto-pause.

For Activity laps, the performance metrics C<MaximumSpeed>, C<MaximumHeartRateBpm>, C<AverageHeartRateBpm>, C<Cadence>, and C<Calories> are also recalculated for each lap (if they were defined). C<StartTime> is also adjusted for the second lap.

For Course laps, C<BeginPosition> and C<EndPosition> are also adjusted. 

Will raise exception unless called in list context.

=back

=cut

sub split {
    my $lap = shift;
    croak 'split() expects to be called in list context' unless wantarray;
    my ($l1, $l2) = $lap->SUPER::split( shift );

    if ($lap->is_activity) {
        $l2->{StartTime} = $l1->trackpoint(-1)->Time;
        for my $l ($l1, $l2 ) {
            $l->{MaximumSpeed} = $l->maximumspeed                if defined $l->MaximumSpeed;
            $l->{MaximumHeartRateBpm} = $l->maximumheartratebpm  if defined $l->MaximumHeartRateBpm;
            $l->{AverageHeartRateBpm} = $l->averageheartratebpm  if defined $l->AverageHeartRateBpm;
            $l->{Cadence} = $l->cadence                          if defined $l->Cadence;

            my $pcent = $l->trackpoints / $lap->trackpoints;
            $l->{_time_auto_paused} = sprintf( '%.2f', $lap->{_time_auto_paused} * $pcent );
            $l->{TotalTimeSeconds}  = sprintf( '%.2f', $l->totaltimeseconds - $l->{_time_auto_paused});
            $l->{DistanceMeters}    = $l->distancemeters;

            $l->{Calories} = sprintf('%.0f', $lap->Calories * $pcent) if defined $l->Calories
        }
    } else {
        $l1->{EndPosition}   =  $l1->trackpoint(-1)->to_basic;
        $l2->{BeginPosition} =  $l2->trackpoint( 1)->to_basic;
        $l2->trackpoint(1)->distance_elapsed(0, force => 1 );
        $l2->trackpoint(1)->time_elapsed(    0, force => 1 );
        for my $l ($l1, $l2 ) {
            my $pcent = $l->trackpoints / $lap->trackpoints;
            $l->{_time_auto_paused} = sprintf( '%.2f', $lap->{_time_auto_paused} * $pcent );
            $l->{TotalTimeSeconds}  = sprintf( '%.2f', $l->totaltimeseconds - $l->{_time_auto_paused});
            $l->{DistanceMeters}   = $l->distancemeters
        }
    }
    return $l1, $l2
}

=over 4

=item reverse( # )

This method is allowed only for Courses and returns a clone of the lap object with the order of the trackpoints reversed.

  $reversed = $lap->reverse;

When reversing a course, the time and distance information is set at 0 at the first trackpoint. Therefore, the lap aggregates (C<DistanceMeters>, C<TotalTimeSeconds>) may be smaller by a few seconds and meters compared to the original lap due to loss of elapsed time and distance information from the original lap's first point.

=back

=cut

sub reverse {
    my $l = shift->clone;
    croak 'reverse() can only be used on Course laps' unless $l->is_course;

    $l = $l->SUPER::reverse;
    $l->trackpoint(1)->time_elapsed( 0, force => 1);
    # will always be 0 for a reversed lap because I never estimate time b/w
    # the last point of a track and the EndPosition (would not make sense)
    $l->{BeginPosition} = $l->trackpoint( 1)->to_basic;
    $l->{EndPosition}   = $l->trackpoint(-1)->to_basic;
    # if we assign an existing trackpoint to Begin/EndPos, should we strip the non-positional info?
    # we could get the xml_string from the trakcpoints and create a new point with just the <Position>...</Position> stuff.
    # I think we should, think about it
    $l->{DistanceMeters}   = $l->distancemeters;
    $l->{TotalTimeSeconds} = $l->totaltimeseconds;
    return $l
}

=head2 AUTOLOAD Methods

=over 4

=item I<field>( $value )

Methods with respect to certain fields can be autoloaded and return the current or newly set value.

Possible fields for Activity laps consist of: C<AverageHeartRateBpm>, C<Cadence>, C<Calories>, C<DistanceMeters>, C<Intensity>, C<MaximumHeartRateBpm>, C<MaximumSpeed>, C<TotalTimeSeconds>, C<TriggerMethod>, C<StartTime>.

Course laps contain aggregates such as C<DistanceMeters>, C<TotalTimeSeconds> but not much else. They also contain C<BeginPosition> and C<EndPosition> which are exclusive to courses. They also contain C<Intensity> which almost always equal to 'Active'.

Some fields may contain a value of 0, C<Calories> being one example. It is safer to check if a field is defined with C<< if (defined $lap->Calories) >> rather than C<< if ($lap->Calories) >>.

Caution should be used if setting a I<$value> as no checks are performed to ensure the value is appropriate or in the proper format.

=back

=cut

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
    croak "invalid attribute method: -> $attr()" unless $possible_attr{$attr};
    $self->{$attr} = shift if @_;
    return $self->{$attr};
}

=head2 Object Methods

=over 4

=item is_activity()

=item is_course()

True if the given lap is of the type indicated by the method, false otherwise.

=back

=cut

sub is_activity { return (shift->StartTime) ? 1 : 0 }
sub is_course   { return (shift->StartTime) ? 0 : 1 }

=over 4

=item time_add( @duration )

=item time_subtract( @duration )

Perform L<DateTime> math on the timestamps of each trackpoint in the lap by adding or subtracting the specified duration. Return true.

The duration can be provided as an actual L<DateTime::Duration> object or an array of arguments as per the syntax of L<DateTime>'s C<add()> or C<subtract()> methods. See the pod for C<< Geo::TCX::Trackpoint->time_add() >>.

=back

=cut

sub time_add {
    my $l = shift;
    my @duration = @_;
    $l->SUPER::time_add( @duration);

    if ($l->is_activity) {
        # need to increment StartTime as well since not <=> Time of 1st point
        my $fake = _fake_starttime_point( $l->{StartTime} );
        $fake->time_add(@duration);
        $l->{StartTime} = $fake->Time
    }
    return 1
}

sub time_subtract {
    my $l = shift;
    my @duration = @_;
    $l->SUPER::time_subtract( @duration);

    if ($l->is_activity) {
        # need to increment StartTime as well since not <=> Time of 1st point
        my $fake = _fake_starttime_point( $l->{StartTime} );
        $fake->time_subtract(@duration);
        $l->{StartTime} = $fake->Time
    }
    return 1
}

sub _fake_starttime_point {
    my $starttime = shift;
    my $fake_pt = Geo::TCX::Trackpoint::Full->new("<Trackpoint><Time>$starttime</Time><Position><LatitudeDegrees>45.5</LatitudeDegrees><LongitudeDegrees>-72.5</LongitudeDegrees></Position><DistanceMeters>0</DistanceMeters></Trackpoint>");
    return $fake_pt
}

=over 4

=item distancemeters()

=item totaltimeseconds()

=item maximumspeed()

=item maximumheartratebpm()

=item averageheartratebpm()

=item cadence()

Calculate and return the distance meters, totaltimeseconds, maximum speed (notionally corresponding to a lap's C<DistanceMeters> and C<TotalTimeSeconds> fields) from the elapsed data contained in each point of the lap's track. The heartrate information is calculated based on the C<HeartRateBpm> field of the trackpoints. The cadence is computed from the average cadence of all the trackpoints' C<Cadence> fields.

The methods do not (yet) reset the fields of the lap yet. The two values may differ due to rounding, the fact that the Garmin recorded the aggregate field with miliseconds and some additional distance the garmin may have recorded between laps, etc. Any difference should be insignificant in relation to the measurement error introduced by the device itself.

=back

=cut

sub distancemeters {
    my $l = shift;
    croak 'distancemeters() expects no arguments' if @_;
    my $distancemeters = 0;
    for my $i (1 .. $l->trackpoints) {
        $distancemeters += $l->trackpoint($i)->distance_elapsed
    }
    return $distancemeters
}

sub totaltimeseconds {
    my $l = shift;
    croak 'totaltimeseconds() expects no arguments' if @_;
    my $totaltimeseconds = 0;
    for my $i (1 .. $l->trackpoints) {
        $totaltimeseconds += $l->trackpoint($i)->time_elapsed
    }
    return $totaltimeseconds
}

sub maximumspeed {
    my $l = shift;
    croak 'maximumspeed() expects no arguments' if @_;
    my ($max_speed, $speed) = (0);
    for (1 .. $l->trackpoints) {
        $speed = $l->trackpoint($_)->distance_elapsed / $l->trackpoint($_)->time_elapsed;
        $max_speed = $speed if $speed > $max_speed
    }
    return sprintf("%.3f", $max_speed )
}

sub maximumheartratebpm {
    my $l = shift;
    croak 'maximumheartratebpm() expects no arguments' if @_;
    croak 'lap has no heart rate information' unless $l->MaximumHeartRateBpm;
    my ($max_hr, $hr) = (0);
    for (1 .. $l->trackpoints) {
        $hr = $l->trackpoint($_)->HeartRateBpm;
        $max_hr = $hr if $hr > $max_hr
    }
    return sprintf("%.0f", $max_hr)
}

sub averageheartratebpm {
    my $l = shift;
    croak 'averageheartratebpm() expects no arguments' if @_;
    croak 'lap has no heart rate information' unless $l->AverageHeartRateBpm;
    my $n_points = $l->trackpoints;
    my $sum_hr;
    for (1 .. $n_points) {
        $sum_hr += $l->trackpoint($_)->HeartRateBpm
    }
    return sprintf("%.0f", $sum_hr / $n_points)
}

sub cadence {
    my $l = shift;
    croak 'cadence() expects no arguments' if @_;
    croak 'lap has no cadence information' unless $l->Cadence;
    my $n_points = $l->trackpoints;
    my $sum_cadence;
    for (1 .. $n_points) {
        $sum_cadence += $l->trackpoint($_)->Cadence
    }
    return sprintf("%.0f", $sum_cadence / $n_points)
}

=over 4

=item xml_string()

returns a string containing the XML representation of object, useful for subsequent saving into an *.tcx file. The string is equivalent to the string argument expected by C<new()>.

=back

=cut

sub xml_string {
    my ($l, $as_course, $str, %opts);
    $l = shift;
    %opts = @_;
    $as_course = 1 if $opts{course} or $l->is_course;

    my $newline = $opts{indent} ? "\n" : '';
    my $tab     = $opts{indent} ? '  ' : '';

    if ( $as_course ) {
        $str .= $newline . $tab x 3 . "<Lap>"
    } else {
        $str .= $newline . $tab x 3 . "<Lap StartTime=\"" . $l->{StartTime} . "\">"
    }

    # the lap meta data
    $str .= $newline . $tab x 4 . "<TotalTimeSeconds>" . $l->{TotalTimeSeconds} . "</TotalTimeSeconds>" if $l->{TotalTimeSeconds};
    $str .= $newline . $tab x 4 . "<DistanceMeters>"   . $l->{DistanceMeters} . "</DistanceMeters>"     if $l->{DistanceMeters};

    if ( $as_course ) {
        my ($beg, $end, $beg_lat, $beg_lon, $end_lat, $end_lon);
        if ($l->is_course) {
            $beg_lat = $l->BeginPosition->LatitudeDegrees;
            $beg_lon = $l->BeginPosition->LongitudeDegrees;
            $end_lat = $l->EndPosition->LatitudeDegrees;
            $end_lon = $l->EndPosition->LongitudeDegrees;
        } else {
            $beg_lat = $l->trackpoint( 1)->LatitudeDegrees;
            $beg_lon = $l->trackpoint( 1)->LongitudeDegrees;
            $end_lat = $l->trackpoint(-1)->LatitudeDegrees;
            $end_lon = $l->trackpoint(-1)->LongitudeDegrees;
        }
        $str .=	$newline . $tab x 4 . "<BeginPosition>";
        $str .= $newline . $tab x 5 . "<LatitudeDegrees>$beg_lat</LatitudeDegrees>";
        $str .= $newline . $tab x 5 . "<LongitudeDegrees>$beg_lon</LongitudeDegrees>";
        $str .=	$newline . $tab x 4 . "</BeginPosition>";
        $str .=	$newline . $tab x 4 . "<EndPosition>";
        $str .= $newline . $tab x 5 . "<LatitudeDegrees>$end_lat</LatitudeDegrees>";
        $str .= $newline . $tab x 5 . "<LongitudeDegrees>$end_lon</LongitudeDegrees>";
        $str .=	$newline . $tab x 4 . "</EndPosition>";
        $str .= $newline . $tab x 4 . "<Intensity>" . $l->{Intensity} . "</Intensity>" if $l->{Intensity};
        $str .= $newline . $tab x 3 . "</Lap>"
    } else {
        $str .= $newline . $tab x 4 . "<MaximumSpeed>" . $l->{MaximumSpeed} . "</MaximumSpeed>" if $l->{MaximumSpeed};
        $str .= $newline . $tab x 4 . "<Calories>" . $l->{Calories} . "</Calories>" if $l->{Calories};
        $str .= $newline . $tab x 4 . "<AverageHeartRateBpm><Value>" . $l->{AverageHeartRateBpm} . "</Value></AverageHeartRateBpm>" if $l->{AverageHeartRateBpm};
        $str .= $newline . $tab x 4 . "<MaximumHeartRateBpm><Value>" . $l->{MaximumHeartRateBpm} . "</Value></MaximumHeartRateBpm>" if $l->{MaximumHeartRateBpm};
        $str .= $newline . $tab x 4 . "<Intensity>" . $l->{Intensity} . "</Intensity>" if $l->{Intensity};
        $str .= $newline . $tab x 4 . "<Cadence>" . $l->{Cadence} . "</Cadence>" if $l->{Cadence};
        $str .= $newline . $tab x 4 . "<TriggerMethod>" . $l->{TriggerMethod} . "</TriggerMethod>" if $l->{TriggerMethod};
    }

    my $n_tabs = ($as_course) ? 3 : 4;   # <Track> for Activities have one more level of indentation compared to Courses

    $str .= $l->SUPER::xml_string( indent => $opts{indent}, n_tabs => $n_tabs );

    unless ($as_course) {
        $str .= $newline . $tab x 3 . "</Lap>"
    }
    return $str
}

=head2 Overloaded Methods

=over 4

=item +

can concatenate two laps by issuing C<$lap = $lap1 + $lap2> on two Lap objects.

=back

=cut

#
# internal methods

sub _process_remaining_lap_metrics {
    my ($self, $lap_metrics) = @_;
    # Some fields are contained within <Value>#</Value> attr, don't need this
    # will add those back before saving any files
    $$lap_metrics =~ s,\<Value\>(.*?)\<\/Value\>,$1,g;
    while ( $$lap_metrics =~ /\<(.*?)\>(.*?)\<.*?\>/sg ) {
        $self->{$1} = $2
    }
}

sub _avg_speed_meters_per_second {
    my $self = shift;
    return $self->DistanceMeters / $self->TotalTimeSeconds
}

sub _avg_speed_km_per_hour {
    my $self = shift;
    return $self->_avg_speed_meters_per_second * 3600 / 1000
}

=head1 EXAMPLES

Coming soon.

=head1 AUTHOR

Patrick Joly

=head1 VERSION

1.04

=head1 SEE ALSO

perl(1).

=cut

1;

