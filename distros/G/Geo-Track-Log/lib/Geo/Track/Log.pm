package Geo::Track::Log;

use 5.005001;
use Time::Piece;
use XML::Simple;
use Carp;
use vars '*interpolate';
use strict;
use Data::Compare;
use Data::Dumper;
#use warnings;

our $VERSION = '0.02';

###########################################################################
sub new {
    my ($class, $params) = @_;
    my $self = bless {}, $class; 

    # set reasonable defaults

    # load the passed parameters
    foreach my $key (%$params) {
        $self->{$key} = $params->{$key};
    }
    return $self;
}


###########################################################################
# loadTrackFromGPX - pass me a filehandle and I will load a track log.
#
sub loadTrackFromGPX {
    my ($self, $file) = @_;
    my $xml = XML::Simple->new(
       ForceArray => [ 'trk', 'trkseg', 'trkpt' ],
       KeyAttr    => [],
       NormaliseSpace => 2
    );

    my $gpx = eval { $xml->XMLin($file) } or die "Invalid GPX track: $@";
    for my $trk (@{$gpx->{trk}}) {
	for my $seg (@{$trk->{trkseg}}) {
		for my $pt (@{$seg->{trkpt}}) {
		    $pt->{time} =~ y/TZ/ /d; # "2004-08-29T01:44:11Z" -> "2004-08-29 01:44:11"
		    $self->addPoint({
				lat => $pt->{lat}, 
				long => $pt->{lon}, 
				elevation => $pt->{ele},
				timestamp => $pt->{time}
				});
		}
	}
    }
}


###########################################################################
# loadTrackFromGarnix - pass me a filehandle and I will load a track log.
#
sub loadTrackFromGarnix {
    my ($self, $FH) = @_;
    while (my $st = <$FH>) { 
	chomp $st;
	next unless $st =~ /^\s*-?\d/o;
	$st =~ s/^\s+//gos;

	my $pt = $self->fixGarnixTrackLine($st);
	$self->addPoint($pt);
    }
}
sub output_track_text{
    my $self = shift;
    print "lat\t";
    print "long\t";
    my $pt = $self->{log}->[0];
    foreach my $k (sort keys %$pt) {
            next if ($k =~ /lat/i);
            next if ($k =~ /long/i);
            print $k . "\t";
    }
    print "\n";

    foreach my $pt (@{$self->{log}}) {
        print $pt->{lat} . "\t";
        print $pt->{long} . "\t";
        foreach my $k (sort keys %$pt) {
            next if ($k =~ /lat/i);
            next if ($k =~ /long/i);
            print $pt->{$k} . "\t";
        }
        print "\n";
    }
}




# this has a problem!!!  fixGarnixWayLine has the problem that 
# waypoint names used to be space delimited, but waypoints from 
# the rino have names that _can_ be in quotes and include spaces.
sub loadWayFromGarnix {
    my ($self, $FH) = @_;
    while (my $st = <$FH>) { 
        chomp $st;
        next unless $st =~ /^\s*-?\d/o;
        $st =~ s/^\s+//gos;

        my $pt = $self->fixGarnixWayLine($st);
        $self->addPoint($pt);
    }
}

###########################################################################
# fixGarnixTrackLine
# Take this:
#44?  3' 33.23" -123?  5'  0.07" 148.0 WGS84 00:50:19-2004/07/12 [1];
#  And return a canonical $pt, a hashref to glory, or at least, the
#  Garnix information in a handy form.
sub fixGarnixTrackLine {
	my ($self, $st) = @_;
	
	my ($pt, @lat, @long, $date, $time);

	# this is a garnix line
	#44?  3' 33.23" -123?  5'  0.07" 148.0 WGS84 00:50:19-2004/07/12 [1];
	# the ? is 'really' a degree symbol

	# this splits that line based on spaces.
	(@lat[0..2], @long[0..2], $pt->{elevation}, $pt->{datum}, 
		$pt->{timestamp}, $pt->{segment}) = split /\s+/, $st;

	$pt->{lat}  = dms_to_deg(@lat);
	$pt->{long} = dms_to_deg(@long);
	next unless $pt->{lat} and $pt->{long};

	($pt->{time}, $pt->{date}) = split /-/, $pt->{timestamp};
	$pt->{date} =~ s|/|-|g;
	$pt->{timestamp} = $pt->{date} . ' ' . $pt->{time};
	$pt->{segment} =~ s/\D//gos;

	# remove leading and trailing spaces from all fields
	foreach my $f qw(lat long elevation timestamp date time segment) {
		$pt->{$f} =~ s/(^\s+)|(\s+$)//g;
	}

	return $pt
}



sub fixGarnixWayLine {
	my ($self, $st) = @_;
    $st =~ s/^\s+//g;
	
	my ($pt, @lat, @long, $date, $time, $name, $comment);
    my @rest;

	# this is a garnix line

    # way line
    #38? 18' 11.5" -123?  3' 27.8" 0.0 WGS84   ADV2 "CRTD 14:37 15-OCT-00";

    # but this is also a wayline: note the space in the waypoint name
    # 'FELIX CAFE'.
    #33� 47' 14.77" -117� 51' 12.67" 55.0 WGS84 "FELIX CAFE" "" [knife N];
   
    # I think I am safe through the datum, then it becomes space delimited
    # with optional quotes that mean disregard the space.

    # this splits that line based on spaces.
    (@lat[0..2], @long[0..2], $pt->{elevation}, $pt->{datum},
        @rest) = split /\s+/, $st;
    my $rest = join ' ', @rest;

    # name and comment parsing

    # is the name in comments?
    if ( $rest =~ s/^"([^"]+)"//) {
        $pt->{name} = $1;
    } else {
        $rest =~ s/^([\S]+)\s//;
        $pt->{name} = $1;
    }

    # comment includes the waypoint symbol, but I can't deal
    # with that at this point...
    $pt->{comment} = $rest;

	$pt->{lat}  = dms_to_deg(@lat);
	$pt->{long} = dms_to_deg(@long);
	return undef  unless $pt->{lat} and $pt->{long};

	#($pt->{time}, $pt->{date}) = split /-/, $pt->{timestamp};
	#$pt->{date} =~ s|/|-|g;
	#$pt->{timestamp} = $pt->{date} . ' ' . $pt->{time};
	#$pt->{segment} =~ s/\D//gos;

	# remove leading and trailing spaces from all fields
	foreach my $f qw(lat long elevation ) {
		$pt->{$f} =~ s/(^\s+)|(\s+$)//g;
	}

	return $pt
}

###########################################################################
# addPoint - give me a hashref with at least lat, long, and timestamp
# and we will live sweetly on the good earth.
sub addPoint {
	my ($self, $p)  = @_;
	$self->{dirty} = 1;
	# this is to clear elevation non initialized warnings.  but 
	# the positive assertion '0' is not actually correct.  Damn
	# but thinking can be hard.
	$p->{elevation} = $p->{elevation} || 0;

	# take the hashref that was passed, and add it to this list of points.
	push @{$self->{log}}, $p;
}


###########################################################################
# take a garnix track log formatted string containing  lat or long, return 
# a decimal degree.  Ror now assume positive (north) lat and negative (western) long.
sub dms_to_deg {
    my ($deg, $min, $sec) = @_;
    s/\D+$//o for ($deg, $min, $sec);
    my $dd = abs($deg) + $min/60 + $sec/3600;
    $dd *= $deg / abs($deg) if $dd;
    return $dd;
}

###########################################################################
# minTimeStamp and maxTimeStamp return the pt that has the earliest
# and latest non-null time stamps.

# calcMinMaxTimeStamp -> based on $self->{dirty} calculates 
# $self->{minTimeStamp} and $self->{maxTimeStamp}.  So you can call 
# minTimeStamp and maxTimeStamp  as often as you wish, only the first call 
# takes any real processing.  (and that is just a simple array traversal.)
sub calcMinMaxTimeStamp {
	my $self=shift;

	$self->{maxTimeStamp} = {timestamp => ""};
	$self->{minTimeStamp} = {timestamp => ""};

	foreach my $pt (@{$self->{log}} ) {

		# shrink it...
		my $ts = $pt->{timestamp};

		# valid timestamp?  pretty weak test... just yy-
		next unless ($ts =~ m|\d\d-|);
		
		# do we have a min? either we don't have a min, so 
		# use this one, or this one is the same or less then 
		# our current min.
		$self->{minTimeStamp} = $pt if ( ($ts le $self->{minTimeStamp}->{timestamp}) 
						or (! $self->{minTimeStamp}->{timestamp}) );

		$self->{maxTimeStamp} = $pt if ( ($ts gt $self->{maxTimeStamp}->{timestamp}) 
						or (! $self->{maxTimeStamp}->{timestamp}) );
		
	}
	#print "min in calc" . Dumper($self->{minTimeStamp});
	#print "max in calc" . Dumper($self->{maxTimeStamp});
	$self->{dirty}=0;
}

###########################################################################
sub minTimeStamp{
	my $self = shift;
	if ($self->{dirty}) {
		$self->calcMinMaxTimeStamp();
	}
	return $self->{minTimeStamp};
}

###########################################################################
sub maxTimeStamp{
	my $self = shift;
	if ($self->{dirty}) {
		$self->calcMinMaxTimeStamp();
	}
	return $self->{maxTimeStamp};
}


###########################################################################
# whereWasI() - accept a timestamp in the same format and timezone as our
# track log, and try and determine where we were...
sub whereWasI {
	my ($self, $d) = @_;
	my $sPt = $self->minTimeStamp();
	my $ePt = $self->maxTimeStamp();

	#
	# TODO: make this routine not suck to find the 1 or 2 points needed to
	# interpolate the position

	# get start point
	foreach my $pt (@{$self->{log}} ) {
		$sPt = $pt if ( $d ge $pt->{timestamp} );
		$ePt = $pt;	
		last if ($d lt $pt->{timestamp});
	}
	
	# what percentage of the way between $sPt->{timestamp} and $ePt->{timestamp} is $d?
	my $pct = $self->getPercent($d, $sPt, $ePt);	

	# What we know:
	#	$sPt->{lat} 
	#	$sPt->{long}
	#	$ePt->{lat} 
	#	$ePt->{long}
	# 	$pct = the percentage of the way we pass from sPt to ePt for our point.

	# load pt $pt with the interpolated lat, long, elevation, and ?
	my $pt;
	
	$pt->{lat} = sprintf "%.6f",
		$sPt->{lat} + ($ePt->{lat} - $sPt->{lat}) * $pct;

	$pt->{long} = sprintf "%.6f",
		$sPt->{long} + ($ePt->{long} - $sPt->{long}) * $pct;

	$pt->{elevation} = sprintf "%.1f",
		($sPt->{elevation} + $ePt->{elevation}) / 2; 

	$pt->{timestamp} = $d;
	$pt->{pct} = $pct;

	return ($pt, $sPt, $ePt);
}

# a synonym for whereWasI
*interpolate = \&whereWasI;

sub getPercent {
	my ($self, $d, $sPt, $ePt) = @_;
	my $st = Time::Piece->strptime( $sPt->{timestamp}, "%Y-%m-%d %H:%M:%S" );
	my $et = Time::Piece->strptime( $ePt->{timestamp}, "%Y-%m-%d %H:%M:%S" ); 
	my $dt = Time::Piece->strptime( $d, "%Y-%m-%d %H:%M:%S" ); 

	return 0 unless $st and $et and $dt;

	my $fulldiff = $et->epoch - $st->epoch;
	my $pct = ($dt->epoch - $st->epoch)/$fulldiff;
	return $pct;
}


# accept a ref to an array Geo::Track::Log objects and 
# then return the distinct union of all of them.
#
# note: This method seems to work fine, but it doesn't have tests (ack!)
# it isn't documented, and it has development comments within...
sub combine_waypoint{
	my ($self, $log_list) = @_;


    # this doesn't really work yet.  In fact, fixGarnixWayLine seems to 
    # not really work in all cases.

    # hash of hashes key = name, value = a hashref representing a point
    my %list;

    # this only works for 'waypoints' which for this are defined
    # as Geo::Track::Log objects that contain a name field.

    # I don't have a way to address points by name or identifier.
    foreach my $log (@$log_list) {
        #print "$log->{name}\n";
        foreach my $pt (@{$log->{log}}){
            # I want something like this, but I can't 
            # have it because I can't address points by name
            # or identifier, and so this requires a complete
            # walk of the list of points for every point added.
            #$self->addPointNonDupe($pt);

            # add this point to list unless it is a dupe
            
            # just add the point and see what happens...
            # this logic means don't add duplicate names, but 
            # that means we lose points if we have name collisions.
            # my 'home' today and my home 'tomorrow' have the same
            # name, but are different points.

            my $add = 0;
            # if I used some hash of values in the hash this would
            # be trivial...
            if (! $list{$pt->{name}}){
                # we don't have this point in our list at all
                $add = 1;
                #$list{$pt->{name}} = $pt;
            } else {
                # we have one point in the list with this name, but
                # perhaps this point has different information.  Say
                # the same name but a different lat,long, or a different
                # date or comment.
                
                # need to compare this pt with each point already
                # in the array pointed to by $list{name}
              
                # add = 0.  Do we want to add this?
                # only if it Compare() == 0 for all points. 
                my $flag; 
                foreach my $oldpt (@{$list{$pt->{name}}}){
                    # is it different ?
                    $flag += Compare( $oldpt, $pt);
                    # what about distance?
                    # if the names are the same, the CRTD field
                    # is the same, and the lat and long are the 
                    # same to 4 decimal places then let it be.
                    if ($pt->{CRTD} eq $oldpt->{CRTD}) {
                        # do something with distance?

                        # assume it is a dupe
                        my $dupe = 1;
                        # this needs code to determine if it is a dupe!
                        
                    }
                } 
                 
                $add = ! $flag;
            }
             
            if ($add) {
                push @{$list{$pt->{name}}}, $pt;
            }
        }
    }
    foreach my $k (sort keys %list) {
        foreach my $pt (@{$list{$k}}) {
            $self->addPoint($pt);
        }
    }
    
}



1;


__END__

=head1 NAME

Geo::Track::Log - Represent track logs and find a location based on a track log and a date.

=head1 SYNOPSIS

  use Geo::Track::Log;
  my $log = new Geo::Track::Log;

  # add a point to a track log.
  $log->addPoint( {
                timestamp => '2004-12-25 12:00:00',
                lat => 0.0,
                long=> 0.0,
  } );

  $log->addPoint( {
                timestamp => '2004-12-25 13:00:00',
                lat => 0.0,
                long=> 1.0,
  } );

  Get our location at a time
  my ($pt, $sPt, $ePt) = $log->whereWasI('2004-12-25 12:30:00');
  or (a synonym)
  my ($pt, $sPt, $ePt) = $log->interpolate('2004-12-25 12:30:00');
  (see DESCRIPTION for more)

  Load tracklog from a Garnix format file
  $log->loadTrackFromGarnix('file handle');

  Load Waypoint from a Garnix format file
  $log->loadWayFromGarnix('file handle');

  Fix the funky Garnix line format
  my $pt = $log->fixGarnixTrackLine ( qq( 44?  3' 33.23" -123?  5'  0.07" 148.0 WGS84 00:50:19-2004/07/12 [1];) )

  Load a GPX (GPS XML) format file
  $log->loadTrackFromGPX('file handle');

  return the earliest point, by time
  my $pt = $log->minTimeStamp();

  return the latest point, by time
  my $pt = $log->maxTimeStamp();

  What percent of the way is time $d between the time at points $sPt and $dPt?
  my $pct = $self->getPercent($d, $sPt, $ePt);	

  
=head1 DESCRIPTION

  whereWasI()?

  So we were on the equator and the prime meridean at noon on Christmas.
  And one degree of longitude (69 statute miles) at 13:00 (1:00pm).  Assuming
  we operated at constant velocity, where were we at 12:30?

  $pt = the interpolated point in between the start point ($sPt) and end
  point ($ePt).  The points on each side of the line are included because
  it seemed to make sense.

  The midpoint will be calculated based on a straight linear transfer.  A 
  line is metaphorically drawn from $sPt to $ePt.  Then the times are compared
  with the time passed to whereWasI(), and the program moves proportionally
  up the line from start point to end point.

  Note: this calculation is not literally correct because it doesn't strictly
  do a Great Circle route calculation.  The Great Circle route calculation
  (as well as lots of great Great Circle information) is shown here:
  http://williams.best.vwh.net/avform.htm#Intermediate

  Since I didn't really understand it, I'll leave it at 'patches welcome.'

  At the equator the distance from (0,0) to (1,1) is about 97 statute miles.
  from (45,0) to (46,1) is about 84 miles, so caveat emptor.

  The method 'interpolate' is offered as a synonym for whereWasI(), in case you 
  are using someone else's track log."

  load track points from a Garnix format file
  $log->loadTrackFromGarnix('filename');

  Garnix format looks like this:
  44?  3' 33.23" -123?  5'  0.07" 148.0 WGS84 00:50:19-2004/07/12 [1];

  The '?' should be a degree marker.  The code handles that.

  Garnix also has options to use the abbreviations 'deg' 'min' and 'sec' in
  place of the symbols.  As well as having a -y flag to output data in 
  Waypoint+ format.  The code doesn't handle that.  Sorry.
  
=head1 EXPLICATION

  Geo::Track::Log provides a class to represent, manage, and manipulate track
  logs.  At the simplest level, a track log is a series of coordinates that 
  represent the virtual bread crumbs of a journey.  As a series of points a 
  track log needs no special class.  Throw it into an array of hash refs
  and off you go.  This structure is easy to extend to handle track point 
  level extensions.  

  And once you have lat/long geo data there are many attributes you can
  add.  Timestamps? altitude? velocity?  Just fields in the hash ref.

  And that is what I did while working on the Geo::Track::Animate module.  
  But as happens with software in development, the attributes of a track 
  log have grown.   First was the need for a name.  But that was easy.  No
  need to break the model.  A scalar name and a scalar pointer to an array
  of hashrefs containing track point level attributes.

  And then I started to throw track logs around.  Take this set of track 
  logs and plot them on a map, and then take this other set and aggregate
  them into one track log to animate together.

  No problem!  Perl is great!  Arrays of hash refs are wonderful!  Life is
  good!

  And next I wanted to animate multiple track logs and display each one in 
  a different color.  But hey, that is just a presentation level requirement,
  and so why would it live with the track log?  And so I told myself these
  stories while working on the code.

  But all the stories came to an end when I wanted to display a descriptive
  label on my track logs.  First I assumed I would use the track log name
  as my label.  The problem arose that my track logs were stored in individual
  files, and my file naming convention is not presentation layer friendly.

  I'm a bit of a geek, but even I was offended by an animated map with track
  logs labeled 'tk04032004.txt' and 'tk04052004.txt.'  And I wasn't going to 
  change my file naming conventions since aside from its' tersness, 
  'tk04032004.txt' is a more precise name then 'Tuesday bike commute.'

  And all of this is a round about way of getting to the point.  In biology
  ontogeny recapitulates philogeny while in software, perhaps especially 
  in Perl (which after all is less software than some variation on runic 
  majick) every program evolves in its conception of data from the simple
  to the complex and on until the program is subsumed into a pure 
  representation as data.

  When the actual masters like zool and danbri talk, it is nearly pure
  ontology, with an afterthought instruction to the data telling it
  to instantiate itself and perform.

  Long ago I stumbled on one of my mantras of software development.
  Simple data leads to complex code, and complex data allows for 
  simple code.

  The complexity has to live somewhere.

  And all of this leads to the basic knowledge that a module called
  Geo::Track::Log is just one step along the path of creating an 
  ontology of place.


=head2 EXPORT

  We don't need no steenking exports!  We are OO geeks now.

=head1 SEE ALSO

  More on Great Circles
  http://williams.best.vwh.net/avform.htm#Intermediate

  http://www.mappinghacks.com

  Geo::Track::Animate
  Audio::DSS

=head1 AUTHORS

  Rich Gibson, E<lt>rgibson@cpan.orgmE<gt>

  Schuyler Erle E<lt>schuyler@nocat.netE<gt> GPX support and general help


  Thanks to: 
  Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Rich Gibson 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

