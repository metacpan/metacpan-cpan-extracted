package Geo::GoogleEarth::Document::LineString;
use strict;
use base qw{Geo::GoogleEarth::Document::Base};

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.02';
}

=head1 NAME

Geo::GoogleEarth::Document::LineString - Geo::GoogleEarth::Document::LineString

=head1 SYNOPSIS

  use Geo::GoogleEarth::Document;
  my $document=Geo::GoogleEarth::Document->new();
  my $placemark = $document->placemark();
  $placemark->LineString( extrude=>boolean, tessellate=>boolean, coordinates=>coor  );

=head1 DESCRIPTION

Geo::GoogleEarth::Document::LineString is a L<Geo::GoogleEarth::Document::Base> with a few other methods.

=head1 USAGE

  my $LineString = $placemark->LineString( extrude=>boolean, tessellate=>boolean, 
														 coordinates=>coor  );

=head1 CONSTRUCTOR

=head2 new

  my $LineString = $placemark->LineString( extrude=>boolean, tessellate=>boolean, 
														 coordinates=>coor  );

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$LineString->type;

=cut

sub type {
  my $self=shift();
  return "LineString";
}

=head2 structure

Returns a hash reference for feeding directly into L<XML::Simple>.

  my $structure=$style->structure;
<LineString id="ID">
  	<!-- specific to LineString -->
	<extrude>0</extrude>                   <!-- boolean -->
	<tessellate>0</tessellate>             <!-- boolean -->
   <altitudeMode>clampToGround</altitudeMode> 
	<!-- kml:altitudeModeEnum: clampToGround, relativeToGround, or absolute -->
   <coordinates>...</coordinates>         <!-- lon,lat[,alt] -->
</LineString>

=cut

sub structure {
	my $self = shift();
	my $structure = { id=>$self->id };
	my %skip=map {$_=>1} (qw{id});

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
