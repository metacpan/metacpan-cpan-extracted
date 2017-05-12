package Geo::GoogleEarth::Document::LinearRing;
use strict;
use base qw{Geo::GoogleEarth::Document::Base};

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.01';
}

=head1 NAME

Geo::GoogleEarth::Document::LinearRing - Geo::GoogleEarth::Document::LinearRing

=head1 SYNOPSIS

  use Geo::GoogleEarth::Document;
  my $document=Geo::GoogleEarth::Document->new();
  my $placemark = $document->placemark();
  $placemark->LinearRing( extrude=>boolean, tessellate=>boolean, coordinates=>coor
								  altitudeMode => mode );

=head1 DESCRIPTION

Geo::GoogleEarth::Document::LinearRing is a L<Geo::GoogleEarth::Document::Base> with a few other methods.

=head1 USAGE

  my $LinearRing = $placemark->LinearRing( extrude=>boolean, tessellate=>boolean, 
														 coordinates=>coor, altitudeMode => mode  );

=head1 CONSTRUCTOR

=head2 new

  my $LinearRing = $placemark->LinearRing( extrude=>boolean, tessellate=>boolean, 
														 coordinates=>coor, altitudeMode => mode  );

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$LinearRing->type;

=cut

sub type {
  my $self=shift();
  return "LinearRing";
}

=head2 structure

Returns a hash reference for feeding directly into L<XML::Simple>.

  my $structure=$style->structure;
<LinearRing id="ID">
	<!-- specific to LinearRing -->
	<extrude>0</extrude>                       <!-- boolean -->
	<tessellate>0</tessellate>                 <!-- boolean -->
	<altitudeMode>clampToGround</altitudeMode> 
	<!-- kml:altitudeModeEnum: clampToGround, relativeToGround, or absolute -->
	<coordinates>...</coordinates>             <!-- lon,lat[,alt] tuples --> 
</LinearRing>

=cut

sub structure {
	my $self = shift();
	my $structure = { id=>$self->id };
	my %skip=map {$_=>1} (qw{id coordinates});

	if ($self->coordinates) {
		my ( @points ) = split( / /, $self->coordinates );
		# The first and last points in the ring must be the same
		if ( $points[0] ne $points[-1] ) {
			push @points, $points[0];
			$self->coordinates( join( " ", @points ) );
		}
		# A LinearRing has a minimum of four points
		return unless (scalar( @points ) > 3 );

		$structure->{'coordinates'} = {content=>$self->coordinates};
	} else {
		return;
	}

	foreach my $key (keys %$self) {
		next if exists $skip{$key};
		$structure->{$key} = {content=>$self->function($key)};	 
	}
	return $structure;
}

=head2 id

=cut

sub id {
  my $self=shift();
  $self->{'id'}=shift() if (@_);
  return $self->{'id'};
}

=head2 coordinates

=cut

sub coordinates {
	my $self = shift();
	$self->{'coordinates'}=shift() if (@_);
	return $self->{'coordinates'};
}

=head1 BUGS

=head1 SUPPORT

	Contact the author.

=head1 AUTHOR

	David Hillman
	CPAN: DAHILLMA

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Document> creates a GoogleEarth KML Document.

=cut

1;
