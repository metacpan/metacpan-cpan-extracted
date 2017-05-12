package Gpx::Addons::Filter;
#use 5.010_000; use 5.10.0; # perl 5.10, revision 5 version 10 subversion 0
use 5.008_000; use 5.8.0; 
use warnings;
use strict;
use Carp;

# Debugging
#use Smart::Comments '###';
our $DEBUG = 0;

=pod

=head1 NAME

Gpx::Addons::Filter - filter Geo::Gpx-data based on time-boundaries

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.04';

=pod

=head1 SYNOPSIS

The core-function of this module is B<filter_trk> which returns all track-segments of a Geo::Gpx-datastructure, 
with timestamps in a given time-period.

    use Geo::Gpx;
    use Gpx::Addons::Filter;
    
    # ... open the filehandle $fh
    my $gpx = Geo::Gpx->new( input => $fh );  # see documentation of Geo::Gpx for details
    my $all_tracks = $gpx->tracks();
    
    my $selected_tracks = filter_trk($all_tracks, $first_second, $last_second);
    
    # create a new gpx-object and fill it with the selcted tracks
    my $new_gpx = Geo::Gpx->new();
    $new_gpx->tracks( $selected_tracks );

To include waypoints into the export an additional function B<filter_wp> is provided.

    my $bounds = $new_gpx->bounds();            # calculate the boundin-box of the selected tracks
    my $all_wp = $gpx->waypoins();              # export all waypoints from the original GPX-file
    my $sel_wp = filter_wp($all_wp, $bounds);   # select all waypoints within this box
    $new_gpx->waypoints( $sel_wp );             # add these wayponts to the new gpx-object

=head1 EXPORT

=over

=item *

flter_trk

=item *

filter_wp

=back

=cut

use base qw(Exporter);
our @EXPORT_OK = qw( filter_trk filter_wp first_and_last_second_of );

=pod

=head1 FUNCTIONS

=cut

sub filter_trk {

=pod

=head2 filter_trk

This function takes 3 arguments:

=over

=item 1

Reference to a data-structure (tracks) from Geo::Gpx

=item 2

The first second of the time-frame we want to export (UNIX-Time)

=item 3

The last second of the time-frame we want to export (UNIX-Time)

=back

It returns a reference to an array containing all the selected segments. 
This pointer can be used by the waypoints-method of Geo::Gpx to add them to a new GPX-datastructure. 
See the examples in SYNOPSIS.

=head3 Selection-Logic

Segments are never split. If at least one trackpoints creation-time is within the given time-frame, 
the whole segment is returned. Points with a creation-time equal to one of the frame-boundarys are 
considered to be inside of the time-frame. Tracks without any segment are not returned. 

If the second parameter (first-second) is undef, all segments up to the last-second will be returned.

If the third parameter (last-second) is undef, all segments after the first-second will be returned.

If second and third parameter are undef, all segments will be returned (quiete useless).

=head3 Returnvalues and Warnings

Returns the arraypointer on success (empty if no segments have matched).

The function checks if the timestamp of the last-point in a segment is larger than the one of the fist point. 
A warning is printed that this segment will be completely ignored. Beside of this, the function assumes, 
that the trackpoints in the array are in chronological order. As of this version there is no 
checking, if track-points in the middle of the segment are larger or small than the end-points.

=cut    
    
	use Data::Dumper;
	my $ref = shift;   # ref to a Geo::Gpx-exported track-structure
	my $start = shift; # start-time
	my $end = shift;   # end-time
	
	# Checks for plausibility
	if (not defined $ref) {
	   croak("At least the reference to some data must be passed to this function!\n")
	}
	
	my @tracks;
	foreach my $trk (@{$ref}) {
		my $trackname = $trk->{name};
		### \$trackname: $trackname
		print {*STDERR} "Dump of \$trk:\n" . Dumper($trk) . "\n" if $DEBUG > 2;
		my $filtered; #TODO: ??? ok - vereinfachen??
		SEGMENT: foreach my $seg (@{$trk->{segments}}) {
			print {*STDERR} "Dump of \$seg:\n" . Dumper($seg) . "\n" if $DEBUG > 1;
			my $first_point = $seg->{points}->[0]->{time};
			my $last_point = $seg->{points}->[$#{$seg->{points}}]->{time}; 
			##### frame start-time:         $start
			##### first point in segment:   $first_point
			##### frame end-time:           $end
			##### last  point in segment:   $last_point
			
			# Some checks for plausibility
			if ($first_point > $last_point) {
                carp ("The timestamp of the first point is later than the one of the last point. This segment will be ignored.\n");
                next SEGMENT;
			}
			# TODO:  checking, if track-points in the middle of the segment are larger or small than the end-points
        	
			if (defined $start and defined $end) {
				#### both start and end of timeframe are present - so we want to filter ==> return only segments within time-frame				
                
                # Plausibilitychecks
            	unless ( $start =~ /\d+/ and $end =~ /\d+/ ) {
            	   croak("Start- and end-time must be unix-epoche-seconds!\n")
            	}
                if ($start > $end) {
            	   croak("hmh - you passed an end-time greater than the start-time - this can not work\n")
            	}
            	if ($start < 915148800 or $end < 915148800) {
            	   carp("You are working on track-points dated before Jan 1, 1999 - strange. (Tip: this function accepts epoch-seconds only)")
            	}
            	
            	
            	# Comparing the timeframe with the segments start- and endpoint
				if ( ($first_point < $start) and ($last_point < $start) ) {
					##### Segment is completely outside of time-frame (before)
					next SEGMENT;
				} elsif (($first_point > $end) and ($last_point > $end)) {
					##### Segment is completely outside of time-frame (after)
					next SEGMENT;
				} else {
					##### Segment is inside of timeframe (at least a part of it)
					push @{$filtered->{segments}}, $seg;
				} 
			} elsif (defined $start and not defined $end) {
				#### only start of timeframe present ==> return all segments with later points
				if ($last_point >= $start) {
					push @{$filtered->{segments}}, $seg;
				} else {
					next SEGMENT;
				}
			} elsif (defined $end and not defined $start) {
				#### only end of timeframe present ==> return all segments with earlier points
				if ($first_point <= $end ) {
					push @{$filtered->{segments}}, $seg;
				} else {
					next SEGMENT;
				}
			} else {
				#### ok, we do NOT want to filter ==> return all segments									
				push @{$filtered->{segments}}, $seg;
			}
		}
		if ( defined $filtered->{segments} ) {
			#### Segments within time-frame found => the track is worth getting a name (which we take from the original track-file)
			$filtered->{name} = $trk->{name};
			print STDERR "Dump of \$filtered:\n" . Dumper($filtered) . "\n" if $DEBUG > 2;
			push @tracks, $filtered;
		} else {
			#### No Segments within time-frame found => delete this empty track
			$filtered = undef;
		}
	}
	return \@tracks;
}

sub filter_wp {

=pod

=head2 filter_wp

This function takes 3 arguments:

=over

=item 1

Reference to a data-structure (waypoints) from Geo::Gpx

=item 2

Reference to a bounding-box as created by Geo::Gpx

=item 3

Tolerance (number) for inclusion of nearby-waypoints (see function within_bounds)

=back

It returns a pointer to an array containing all waypoints, which are on or within these bounds.

This pointer can be used by the waypoints-method of Geo::Gpx to add them to a new GPX-datastructure. 
See the examples in SYNOPSIS.

=cut

	use Data::Dumper;
	my $ref = shift;   # ref to a Geo::Gpx-exported track-structure
	my $box = shift;   # ref to bounding-box
	my $tolerance = shift;
	if (not defined $tolerance) {
	   $tolerance = 0;
	}
	my @filtered;
	foreach my $wp (@{$ref}) {
		if ( within_bounds($wp, $box, $tolerance) ) {
			push @filtered, $wp;
		}
	}
	return \@filtered;
}

sub within_bounds {
=pod

=head2 within_bounds

This is a helper-function for filter_wp. 
It returns 1 if a waypoint is on or within the bounds, undef if outside 

=head3 Expected  Parameters

=over 

=item waypoint

Pointer to the waypoint-hash.

mandatory

=item box

Pointer to the bounding-box-hash

mandatory

=item tolerance

Tolerance of waypoints (expands the box slightly so that points near the birder still get included ). 

optional, number

=back

=cut

	my $wp = shift;
	my $box = shift;
	if (not defined $wp or not defined $box) {
	   croak "Both waypoint and box mus be defined!"
	}
	my $tolerance = shift;      
	#### Waypoint: $wp
	#### Bounding-box: $box
	if ( $wp->{lat} <= $box->{maxlat} + $tolerance ) {
		if ( $wp->{lat} >= $box->{minlat} - $tolerance ) {
			if ($wp->{lon} <= $box->{maxlon} + $tolerance ) {
				if ($wp->{lon} >= $box->{minlon} - $tolerance ) {
					return 1;
				}
			}
		}
	}
	return;
}

sub first_and_last_second_of {
    
=pod

=head2 first_and_last_second_of

Gets one day as string in ISO-Format (yyyy-mm-dd) and 
returns the first and last second of this day in UNIX-time.
Returns undef on error.

TODO: Evaluate TZ-Problem

=cut

	use Time::Local;
	my $date_strg = shift;
    if ( $date_strg =~ m{   ^           # nothing in front
                            (\d{4})     # year
                            -           # seperated by a dash
                            (\d{1,2})   # month (may have only one number)
                            -           # seperated by a dash
                            (\d{1,2})   # day (may be one number)
                            $           # nothing after
                        }x
        ){
		my $day = $3;
		my $month = $2-1;   # see documentation of Time::Local for the reason for these calculations

		# Plausibility-Checks
		if ( ($day < 1) or ($day > 31) or (($month + 1) < 1) or ($month + 1 > 12) ) {
			croak 'Did you swap day with month? Valid format is yyyy-mm-dd. Stopped' ;
		}
		my $year = $1;
		### $year: $year
		$year = $year-1900;
		### $year - 1900 (prepared for Time::Local::timegm): $year
		
		if ( (($year + 1900) < 32) or (($year + 1900) > 2037) ) {
			croak 'Years before 32 (Jesus wasn\'t guided by GPS) and after 2037 are not supported. Stopped';
		}
		
		# Calculations (epoche-seconds of 0h and 23:59:59h GMT)
		my $day_0h = timegm(0,0,0,$day,$month,$year);
		my $day_24h = timegm(59,59,23,$day,$month,$year);
		return ($day_0h, $day_24h);
	} else {
		croak 'Format of date must be yyyy-mm-dd! Stopped';
	}
}

1; # End of Gpx::Addons::Filter

__END__

=pod

=head1 AUTHOR

Ingo LANTSCHNER, C<< <perl [at] lantschner.name> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gpx-addons-filter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gpx-Addons-Filter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gpx::Addons::Filter


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gpx-Addons-Filter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gpx-Addons-Filter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gpx-Addons-Filter>

=item * Search CPAN

L<http://search.cpan.org/dist/Gpx-Addons-Filter/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Ingo LANTSCHNER, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut