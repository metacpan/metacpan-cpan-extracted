package Geo::GoogleEarth::Document::LineStyle;
use strict;
use base qw{Geo::GoogleEarth::Document::ColorStyle};

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.02';
}

=head1 NAME

Geo::GoogleEarth::Document::LineStyle - Geo::GoogleEarth::Document::LineStyle

=head1 SYNOPSIS

  use Geo::GoogleEarth::Document;
  my $document=Geo::GoogleEarth::Document->new();
  my $placemark = $document->placemark();
  $placemark->LineStyle( width => width );

=head1 DESCRIPTION

Geo::GoogleEarth::Document::LineStyle is a L<Geo::GoogleEarth::Document::ColorStyle> with a few other methods.

=head1 USAGE

  my $LineStyle = $placemark->LineStyle( width => 2 );

=head1 CONSTRUCTOR

=head2 new

  my $LineStyle = $placemark->LineStyle( width => 2 );

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$LineStyle->type;

=cut

sub type {
  my $self=shift();
  return "LineStyle";
}

=head2 structure

Returns a hash reference for feeding directly into L<XML::Simple>.

my $structure = $LineStyle->structure;
<LineStyle id="ID">
 	<!-- inherited from ColorStyle -->
	<color>ffffffff</color>            <!-- kml:color -->
	<colorMode>normal</colorMode>      <!-- colorModeEnum: normal or random -->

	<!-- specific to LineStyle -->
	<width>1</width>                   <!-- float -->
</LineStyle>

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

=head2 width

Sets or return width

=cut

sub width {
	my $self=shift;
	$self->{width} = shift if ( @_ );
	return $self->{width};
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
