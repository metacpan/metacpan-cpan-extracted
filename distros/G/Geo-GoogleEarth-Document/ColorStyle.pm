package Geo::GoogleEarth::Document::ColorStyle;
use strict;
use base qw{Geo::GoogleEarth::Document::Base};

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.01';
}

=head1 NAME

Geo::GoogleEarth::Document::ColorStyle - Geo::GoogleEarth::Document::ColorStyle

=head1 SYNOPSIS

	None, ColorStyle is an abstract class.

=head1 DESCRIPTION

Geo::GoogleEarth::Document::ColorStyle is a L<Geo::GoogleEarth::Document::Base> with a few other methods.

=head1 USAGE

	None, ColorStyle is an abstract class.

=head1 CONSTRUCTOR

=head2 new

	None, ColorStyle is an abstract class.

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$ColorStyle->type;

=cut

sub type {
  my $self=shift();
  return "ColorStyle";
}

=head2 structure

Returns a hash reference for feeding directly into L<XML::Simple>.

my $structure = $ColorStyle->structure;
<ColorStyle id="ID">
  <color>ffffffff</color>            <!-- kml:color -->
  <colorMode>normal</colorMode>      <!-- kml:colorModeEnum: normal or random -->
</ColorStyle>

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

=head2 color

Sets or returns color

=cut

sub color {
	my $self = shift;
	$self->{color} = shift if ( @_ );
	return $self->{color};
}

=head2 colorMode

Sets or return colorMode

=cut

sub colorMode {
	my $self = shift;
	$self->{colorMode} = shift if ( @_ );
	return $self->{colorMode};
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
