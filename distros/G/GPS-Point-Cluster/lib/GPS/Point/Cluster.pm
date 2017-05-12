package GPS::Point::Cluster;
use strict;
use Geo::Inverse;
use DateTime;

our $VERSION='0.05';

=head1 NAME

GPS::Point::Cluster - Groups GPS Points in to clusters

=head1 SYNOPSIS

  use GPS::Point::Cluster;
  my $cluster=GPS::Point::Cluster->new(
                                        separation => 500,  #meters
                                        interlude  => 600,  #seconds
                                       );
  my @pt=({}, {}, {}, ...); #{lat=>39, lon=>-77, time=>$epoch_seconds}

  foreach my $pt (@pt) {
    my $obj=$cluster->merge_attempt($pt);
    if (defined $obj) {
      print join(",", $cluster->index, $cluster->start_dt, $cluster->end_dt,
                      $cluster->lat, $cluster->lon, $cluster->weight), "\n";
      $cluster=$obj;
    }
  }



=head1 DESCRIPTION

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

  my $cluster = GPS::Point::Cluster->new(separation=>500);

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self = shift();
  %$self=@_;
  $self->GeoInverse(Geo::Inverse->new)
                              unless ref($self->GeoInverse) eq "Geo::Inverse";
  $self->separation(500) unless $self->separation;
  $self->interlude(600) unless $self->interlude;
  $self->index(0) unless $self->index;
  $self->weight(0) unless $self->weight;
}

=head2 settings

Returns a hash of default settings to transfer from one cluster to the next.

  my $hash=$cluster->settings;
  my %hash=$cluster->settings;

=cut

sub settings {
  my $self=shift;
  my @keys=qw{separation interlude GeoInverse};
  my %hash=(index=>$self->index + 1, map {$_=>$self->{$_}} @keys);
  return wantarray ? %hash : \%hash;
}

=head2 index

Returns the cluster index which is a running integer.

=cut

sub index {
  my $self=shift;
  $self->{'index'}=shift if @_;
  return $self->{'index'};
}

=head2 separation

The threshold distance in meters between the cluster and the test point.

=cut

sub separation {
  my $self=shift;
  $self->{'separation'}=shift if @_;
  return $self->{'separation'};
}

=head2 interlude

The threshold duration in seconds between the cluster end time and the test point.

=cut

sub interlude {
  my $self=shift;
  $self->{'interlude'}=shift if @_;
  return $self->{'interlude'};
}

=head2 lat

Latitude in decimal degrees WGS-84.  The latitude is calculated as a mathimatical average of all latitudes that constitute the cluster.

=cut

sub lat {
  my $self=shift;
  $self->{'lat'}=shift if @_;
  return $self->{'lat'};
}

=head2 lon

Longitude in decimal degrees WGS-84.  The longitude is calculated as a mathimatical average of all longitudes that constitute the cluster.

=cut

sub lon {
  my $self=shift;
  $self->{'lon'}=shift if @_;
  return $self->{'lon'};
}

=head2 weight

The count of points that constitute the cluster.

=cut

sub weight {
  my $self=shift;
  $self->{'weight'}=shift if @_;
  return $self->{'weight'};
}

=head2 start

Returns the cluster start date time as seconds from epoch

=cut

sub start {
  my $self=shift;
  $self->{'start'}=shift if @_;
  return $self->{'start'};
}

=head2 start_dt

Returns the cluster start date time as a L<DateTime> object

=cut

sub start_dt {
  my $self=shift;
  unless (defined $self->{'start_dt'}) {
    $self->{'start_dt'}=DateTime->from_epoch(epoch=>$self->start);
  }
  return $self->{'start_dt'};
}

=head2 end

Returns the cluster end date time as seconds from epoch

=cut

sub end {
  my $self=shift;
  $self->{'end'}=shift if @_;
  return $self->{'end'};
}

=head2 end_dt

Returns the cluster end date time as a L<DateTime> object

=cut

sub end_dt {
  my $self=shift;
  unless (defined $self->{'end_dt'}) {
    $self->{'end_dt'}=DateTime->from_epoch(epoch=>$self->end);
  }
  return $self->{'end_dt'};
}

=head2 GeoInverse

Returns a L<Geo::Inverse> object which is used to calculate geodetic distances.

=cut

sub GeoInverse {
  my $self=shift;
  $self->{'GeoInverse'}=shift if @_;
  return $self->{'GeoInverse'};
}

=head2 merge_attempt

Attempts to merge the point into the cluster.  If the point does not fit in the cluster then the method returns a new cluster. If it merged, then it returns undef.

  my $new_cluster=$cluster->merge_attempt($pt);
  if (defined $new_cluster) {
    #New cluster is constructed with $pt as the only member.  $cluster is unmodified.
  } else {
    #$pt is added the cluster.  The cluster is updated appropriately.
  }

=cut

sub merge_attempt {
  my $self=shift;
  my $pt=shift;
  if (    $self->weight
      and $self->distance($pt) < $self->separation
      and $self->duration($pt) < $self->interlude ) {
    $self->merge($pt);
    return undef;
  } else {
    return $self->new(%$pt, $self->settings,
                      start  =>$pt->{'time'},
                      end    =>$pt->{'time'},
                      weight =>1);
  }
}

=head2 distance

Returns the distance in meters between the cluster and the point.

  my $distance=$cluster->distance($pt);

=cut

sub distance {
  my $self=shift;
  my $pt=shift;
  my $distance=$self->GeoInverse->inverse($self->lat => $self->lon,
                                        $pt->{'lat'} => $pt->{'lon'});
  return $distance;
}

=head2 duration

Returns the duration in seconds between the cluster and the point.

  my $duration=$cluster->duration($pt);

=cut

sub duration {
  my $self=shift;
  my $pt=shift;
  return $pt->{'time'} - $self->end;
}

=head2 merge

Merges point into cluster returns cluster.

  my $cluster->merge($pt);

=cut

sub merge {
  my $self=shift;
  my $pt=shift;
  $self->start($pt->{'time'}) unless defined $self->start;
  $self->end($pt->{'time'});
  $self->{'end_dt'}=undef;
  my $weight=$self->weight;
  $self->weight($weight+1);
  $self->lat(($self->lat * $weight + $pt->{'lat'})/$self->weight);
  $self->lon(($self->lon * $weight + $pt->{'lon'})/$self->weight);
  return $self;
}

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    STOP, LLC
    domain=>michaelrdavis,tld=>com,account=>perl
    http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Algorithm::Cluster>, L<Algorithm::ClusterPoints>

=cut

1;
