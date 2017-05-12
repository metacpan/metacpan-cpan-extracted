package Geo::GoogleEarth::Document::LookAt;
use strict;
use base qw{Geo::GoogleEarth::Document::Base};

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.01';
}

=head1 NAME

Geo::GoogleEarth::Document::LookAt - Geo::GoogleEarth::Document::LookAt

=head1 SYNOPSIS

  use Geo::GoogleEarth::Document;
  my $document=Geo::GoogleEarth::Document->new();
  $document->LookAt( latitude => 35, longitude => -98, heading => 6, alt => 3500000, tilt => 5 );

=head1 DESCRIPTION

Geo::GoogleEarth::Document::LookAt is a L<Geo::GoogleEarth::Document::Base> with a few other methods.

=head1 USAGE

  $document->LookAt( latitude => 35, longitude => -98, heading => 6, alt => 3500000, tilt => 5 );

=head1 CONSTRUCTOR

=head2 new

  my $LookAt = $document->LookAt( latitude => 35, longitude => -98, heading => 6, 
											 alt => 3500000, tilt => 5 );

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$LookAt->type;

=cut

sub type {
  my $self=shift();
  return "LookAt";
}

=head2 structure

Returns a hash reference for feeding directly into L<XML::Simple>.

  my $structure=$style->structure;
<LookAt id="ID">
  <longitude>0</longitude>      <!-- kml:angle180 -->
	 <latitude>0</latitude>        <!-- kml:angle90 -->
		<altitude>0</altitude>        <!-- double --> 
		  <heading>0</heading>          <!-- kml:angle360 -->
			 <tilt>0</tilt>                <!-- kml:anglepos90 -->
				<range></range>               <!-- double -->
				  <altitudeMode>clampToGround</altitudeMode> 
						  <!--kml:altitudeModeEnum:clampToGround, relativeToGround, absolute -->
						  </LookAt>

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
