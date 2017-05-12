package GPS::Point::Filter;
use strict;
use DateTime;

our $VERSION='0.02';

=head1 NAME

GPS::Point::Filter - Algorithm to filter extraneous GPS points

=head1 SYNOPSIS

  use GPS::Point::Filter;
  my $gpf=GPS::Point::Filter->new;
  $gpf->addCallback(sample=>\&GPS::Point::Filter::callback_sample);
  my $status=$gpf->addPoint($point);

=head1 DESCRIPTION

GPS::Point::Filter uses a single pass linear algorithm to filter extraneous GPS points from a GPS feed.  The filter uses three tests to determine whether to trigger a callback or not.

The most common use for this type of algorithm is to intelligently reduce the number of points before transmission over a limited bandwidth network.  The filter properties will need to be tuned for particular networks and implementations.

=head1 USAGE

  use GPS::Point::Filter;
  my $gpf=GPS::Point::Filter->new;
  $gpf->addCallback(sample=>\&GPS::Point::Filter::callback_sample);
  my $point=GPS::Point->new(time    => time,
                            lat     => 39,
                            lon     => -77,
                            speed   => 25,
                            heading => 135);
  my $status=$gpf->addPoint($point);
  printf "%s\n", $status if $status;

=head1 CONSTRUCTOR

=head2 new

  my $gpf=GPS::Point::Filter->new(
                                  separation => 2000,  #meters
                                  interlude  => 1200,  #seconds
                                  deviation  => 500,   #meters
                                 );

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head2 initialize

=cut

sub initialize {
  my $self = shift();
  %$self=@_;
  $self->separation(2000) unless defined $self->separation;
  $self->interlude(1200)  unless defined $self->interlude;
  $self->deviation(500)   unless defined $self->deviation;
}

=head1 METHODS (Properties)

=head2 interlude

Sets or returns the filter interlude property.  The interlude is defined as the period of time in seconds for which the previous filter point is still valid or not stale.  The filter will trigger a callback if the GPS sample point does not move when the interlude is exceeded.

  $gpf->interlude(1200); #default is 1200 seconds

=cut

sub interlude {
  my $self=shift;
  if (@_) {
    $self->{'interlude'}=shift;
  }
  return $self->{'interlude'};
}

=head2 separation

Sets or returns the filter separation property.  The separation is defined as the distance in meters between the previous filter point and the sample point.  The filter will trigger a callback when then separation is exceeded.

  $gpf->separation(2000); #default is 2000 meters

=cut

sub separation {
  my $self=shift;
  if (@_) {
    $self->{'separation'}=shift;
  }
  return $self->{'separation'};
}

=head2 deviation

Sets or returns the filter deviation property.  The deviation is defined as the distance in meters between the constant velocity predicted location of the previous filter point and the sample point.   The filter will trigger a callback when then deviation is exceeded.

  $gpf->deviation(500); #default is 500 meters

=cut

sub deviation {
  my $self=shift;
  if (@_) {
    $self->{'deviation'}=shift;
  }
  return $self->{'deviation'};
}

=head1 METHODS

=head2 addCallback

Add a sub reference to the callback hash and returns the $gpf object.  

  $gpf->addCallback(label=>sub{print shift->latlon."\n"});
  $gpf->addCallback(label=>\&mysub);
  sub mysub {
    my $point=shift;#GPS::Point (new point)
    my $gpf=shift;  #GPS::Point::Filter with state info and previous point
    printf "Lat: %s, Lon: %s\n", $point->latlon;
  }

=cut

sub addCallback {
  my $self=shift;
  if (scalar(@_) == 2) {
    my $key=shift;
    my $value=shift;
    $self->{'callback'}={} unless ref($self->{'callback'}) eq "HASH";
    $self->{'callback'}->{$key}=$value;
  } else {
    die("Error: Method addCallback requires two arguments.");
  }
  return $self;
}

=head2 deleteCallback

  my $sub=$gpf->deleteCallback("label");

=cut

sub deleteCallback {
  my $self=shift;
  my $label=shift;
  return delete $self->{'callback'}->{$label};
}

=head2 addPoint

Adds a point to the filter to be tested and returns a short staus string.  If the point is "extraneous", then the filter will not trigger a callback.

  my $point=GPS::Point->new(
                            lat     =>  39.000, #decimal degrees
                            lon     => -77.000, #decimal degrees
                            speed   =>  50.0,   #meters/second
                            heading =>  45.0,   #degrees clockwise from North
                            );
  my $status=$gpf->addPoint($point);
  if ($status) {print "added"} else {print "filtered"}

=cut

sub addPoint {
  my $self=shift;
  my $point=shift;
  die("Error: Point needs to be GPS::Point.")
    unless ref($point) eq "GPS::Point";
  die("Error: Point needs to be at least GPS::Point 0.10.")
    unless $point->VERSION >= 0.10;
  unless (defined $self->point) {
    $self->execute($point);
    return $self->status(sprintf("start: %s", DateTime->now->datetime));
  } else {
    my $interlude=$point->time - $self->point->time;
    if ($interlude > $self->interlude) {
      $self->execute($point);
      return $self->status(sprintf("interlude: %s", $interlude));
    } else {
      my $separation=$point->distance($self->point);
      if ($separation > $self->separation) {
        $self->execute($point);
        return $self->status(sprintf("separation: %s", $separation));
      } else {
        my $track=$self->point->track($interlude);
        my $deviation=$point->distance($track);
        print GPS::Point::Filter::callback_sample_string(Track=>$track)
          if $self->{'debug'};
        if ($deviation > $self->deviation) {
          $self->execute($point);
          return $self->status(sprintf("deviation: %s", $deviation));
        } else {
          return undef;
        }
      }
    }
  }
}

=head2 point

Sets or returns the GPS point stored in the GPS::Point::Filter object.  

  my $point=$gpf->point;

This point is set to the previous filter point when the callback is triggered.  But, is updated just after the execute is complete.

=cut

sub point {
  my $self=shift;
  if (@_) {
    $self->{'point'}=shift;
  }
  return $self->{'point'};
}

=head2 count

Sets or returns the count of number of points that have been filtered since the previous filter point;

  $gpf->count;

=cut

sub count {
  my $self=shift;
  if (@_) {
    $self->{'count'}=shift;
  }
  return $self->{'count'};
}

=head2 status

Sets or returns the status of the previous filter point.

=cut

sub status {
  my $self=shift;
  if (@_) {
    $self->{'status'}=shift;
  }
  return $self->{'status'};
}


=head1 METHODS (Internal)

=head2 callback

Returns the callback hash of sub references.  

  my $callback=$gpf->callback; #{label=>sub{}}
  my %callback=$gpf->callback; #(label=>sub{})

Note: Callbacks are executed sorted by key.

=cut

sub callback {
  my $self=shift;
  return wantarray ? %{$self->{'callback'}} : $self->{'callback'};
}

=head2 execute

Executes all sub references in the callback hash sorted by key.

The $point and the $gpf objects are passed to the sub routine as the first two arguments.

  $gpf->execute;

=cut

sub execute {
  my $self=shift;
  my $point=shift;
  my $callback=$self->callback;
  foreach my $key (sort keys %$callback) {
    &{$callback->{$key}}($point, $self);
  }
  $self->point($point);
  return $self;
}

=head1 Functions (Convenience)

=head2 callback_sample

A very simple callback example.

  GPS::Point::Filter::callback_sample_string($point);

To register

  $gpf->addCallback(sample=>\&GPS::Point::Filter::callback_sample);

=cut

sub callback_sample {
  my $point=shift;
  my $gpf=shift;
  print &callback_sample_string(Filter=>$point);
}

=head2 callback_sample_string

Returns a formated string given a GPS::Point

  my $string=GPS::Point::Filter::callback_sample_string($point);

=cut

sub callback_sample_string {
  my $label=shift;
  my $point=shift;
  return join("\t", $label, $point->time,
                            $point->latlon,
                            $point->speed,
                            $point->heading). "\n";
}

=head1 TODO

I would like to implement a Kalman Filter in order to filter point data instead of the current interlude, separation, and deviation properties.

Add count of points filtered since previous point

Add status to gpf object

=head1 BUGS

Please report bugs to GEO-PERL list

=head1 SUPPORT

Please Try the GEO-PERL list

=head1 AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    domain=>michaelrdavis,tld=>com,account=>perl

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<GSP::Point>, L<GPS::Point::Filter>, L<Net::GSPD>, L<Geo::Forward>, L<Geo::Inverse>

=cut

1;
