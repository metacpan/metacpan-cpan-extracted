package Geo::GoogleEarth::Document::Polygon;
use strict;
use base qw{Geo::GoogleEarth::Document::Base};
use Geo::GoogleEarth::Document::LinearRing;
use Data::Dumper;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.01';
}

=head1 NAME

Geo::GoogleEarth::Document::Polygon - Geo::GoogleEarth::Document::Polygon

=head1 SYNOPSIS

  use Geo::GoogleEarth::Document;
  my $document=Geo::GoogleEarth::Document->new();
  my $placemark = $document->placemark();
  $placemark->Polygon( extrude=>boolean, tessellate=>boolean, outerBoundaryIs => coordinates,
							  innerBoundaryIs => coordinates );

=head1 DESCRIPTION

Geo::GoogleEarth::Document::Polygon is a L<Geo::GoogleEarth::Document::Base> with a few other methods.

=head1 USAGE

  my $Polygon = $placemark->Polygon( extrude=>boolean, tessellate=>boolean, outerBoundaryIs => coordinates,
							  innerBoundaryIs => coordinates );

=head1 CONSTRUCTOR

=head2 new

  my $Polygon = $placemark->Polygon( extrude=>boolean, tessellate=>boolean, outerBoundaryIs => coordinates,
							  innerBoundaryIs => coordinates );

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$Polygon->type;

=cut

sub type {
  my $self=shift();
  return "Polygon";
}

=head2 structure

Returns a hash reference for feeding directly into L<XML::Simple>.

  my $structure=$style->structure;
<Polygon id="ID">
	<!-- specific to Polygon -->
	<extrude>0</extrude>                       <!-- boolean -->
	<tessellate>0</tessellate>                 <!-- boolean -->
	<altitudeMode>clampToGround</altitudeMode> 
	<!-- kml:altitudeModeEnum: clampToGround, relativeToGround, or absolute -->
	<outerBoundaryIs>
		<LinearRing>
			<coordinates>...</coordinates>         <!-- lon,lat[,alt] -->
		</LinearRing>
	</outerBoundaryIs>
	<innerBoundaryIs>
		<LinearRing>
			<coordinates>...</coordinates>         <!-- lon,lat[,alt] -->
		</LinearRing>
	</innerBoundaryIs>
</Polygon>

=cut

sub structure {
	my $self = shift();
	my $structure = { id=>$self->id };
	my %skip=map {$_=>1} (qw{id outerBoundaryIs innerBoundaryIs});

	if ( $self->outerBoundaryIs ) {
		my $LS = Geo::GoogleEarth::Document::LinearRing->new( extrude => $self->extrude, 
																				tesselate => $self->tesselate,
																				coordinates => $self->outerBoundaryIs );
		$structure->{outerBoundaryIs} = {content=>{ LinearRing => $LS->structure }};
	} else {
		return;
	}
	if ( $self->innerBoundaryIs ) {
		my $LS = Geo::GoogleEarth::Document::LinearRing->new( extrude => $self->extrude, 
																				tesselate => $self->tesselate,
																				coordinates => $self->innerBoundaryIs );
		$structure->{innerBoundaryIs} = {content=>{ LinearRing => $LS->structure }};
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

=head2 outerBoundaryIs

=cut

sub outerBoundaryIs {
	my $self = shift;
	$self->{outerBoundaryIs} = shift if ( @_ );
	return $self->{outerBoundaryIs};
}

=head2 innerBoundaryIs

=cut

sub innerBoundaryIs {
	my $self = shift;
	$self->{innerBoundaryIs} = shift if ( @_ );
	return $self->{innerBoundaryIs};
}

=head2 extrude

=cut

sub extrude {
	my $self = shift;
	$self->{extrude} = shift if ( @_ );
	return $self->{extrude};
}

=head2 tesselate

=cut

sub tesselate {
	my $self = shift;
	$self->{tesselate} = shift if ( @_ );
	return $self->{tesselate};
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
