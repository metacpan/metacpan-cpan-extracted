package Geo::GoogleEarth::Document::PolyStyle;
use strict;
use base qw{Geo::GoogleEarth::Document::ColorStyle};

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.02';
}

=head1 NAME

Geo::GoogleEarth::Document::PolyStyle - Geo::GoogleEarth::Document::PolyStyle

=head1 SYNOPSIS

  use Geo::GoogleEarth::Document;
  my $document=Geo::GoogleEarth::Document->new();
  my $placemark = $document->placemark();
  $placemark->PolyStyle( fill => fill, outline => outline );

=head1 DESCRIPTION

Geo::GoogleEarth::Document::PolyStyle is a L<Geo::GoogleEarth::Document::ColorStyle> with a few other methods.

=head1 USAGE

  my $PolyStyle = $placemark->PolyStyle( fill => 1, outline => 1 );

=head1 CONSTRUCTOR

=head2 new

  my $PolyStyle = $placemark->PolyStyle( fill => 1, outline => 1 );

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$PolyStyle->type;

=cut

sub type {
  my $self=shift();
  return "PolyStyle";
}

=head2 structure

Returns a hash reference for feeding directly into L<XML::Simple>.

my $structure = $PolyStyle->structure;
<PolyStyle id="ID">
  <!-- inherited from ColorStyle -->
  <color>ffffffff</color>            <!-- kml:color -->
  <colorMode>normal</colorMode>      <!-- kml:colorModeEnum: normal or random -->

  <!-- specific to PolyStyle -->
  <fill>1</fill>                     <!-- boolean -->
  <outline>1</outline>               <!-- boolean -->
</PolyStyle>

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

=head2 fill

Sets or returns fill

=cut

sub fill {
	my $self = shift;
	$self->{fill} = shift if ( @_ );
	return $self->{fill};
}

=head2 outline

Sets or returns outline

=cut

sub outline {
	my $self = shift;
	$self->{outline} = shift if (@_);
	return $self->{outline};
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
