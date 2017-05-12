package Geo::Google::Location;
use strict;
use warnings;
use Data::Dumper;
use URI::Escape;
use JSON;
use Geo::Google;
our $VERSION = '0.04-rc3';

use constant FMT => <<_FMT_;
<location infoStyle="%s" id="%s">
  <point lat="%s" lng="%s"/>
  <icon image="%s" class="local"/>
  <info>
    <address>
      %s
    </address>
  </info>
</location>
_FMT_

#      $loc->{'latitude'} = $lat;
#      $loc->{'longitude'} = $lng;
#      $loc->{'lines'} = [@lines];
#      $loc->{'id'} = $id;
#      $loc->{'icon'} = $icon;
#      $loc->{'infostyle'} = $infoStyle;

sub new {
  my $class = shift;
  my %arg = @_;
  my $self = bless \%arg, $class;
}

sub icon      { return shift->{'icon'} }
sub id        { return shift->{'id'} }
sub infostyle { return shift->{'infostyle'} }
sub latitude  { return shift->{'latitude'} }
sub lines     { my $self = shift; return $self->{'lines'} ? @{ $self->{'lines'} } : () }
sub longitude { return shift->{'longitude'} }
sub title     { return shift->{'title'} }

sub toXML {
  my $self = shift;
  return sprintf( FMT,
    $self->infostyle(),
    $self->id(),
    $self->latitude(),
    $self->longitude(),
    $self->icon(),
    join('',map {"<line>$_</line>"} $self->lines() ),
  );
}

sub toJSON {
	my $self = shift;
	my $json = new JSON (barekey => 1);

	# Construct the shell of a new perl data structure that we
	# can pass off to the JSON module for rendering to a string
	my $preJSON = Geo::Google::_JSONrenderSkeleton();

	# Fill the perl data structure with information from this
	# location
	$preJSON->{"form"}->{"l"}->{"near"} = $self->title();
	$preJSON->{"form"}->{"q"}->{"q"} = $self->title();
	$preJSON->{"form"}->{"d"}->{"daddr"} = $self->title();
	$preJSON->{"form"}->{"selected"} = "q";
	push( @{$preJSON->{"overlays"}->{"markers"}}, {
		"icon" => "addr",
		"laddr" => $self->title(),
		"svaddr" => $self->title(),
		"lat" => $self->latitude(),
		"lng" => $self->longitude(),
		"id" => "addr",
		"adr" => 1,
		"image" => "/mapfiles/arrow.png",
		"elms" => [(3, 2, 6)],
		"dtlsUrl" => "/maps?v=1&q=" . uri_escape($self->title())
			. "&ie=UTF8&hl=en&latlng=&ei=",
		"infoWindow" => {
				"basics" => join("<BR />", $self->lines()),
				"type" => "html",
				"_" => 0
				}
		});
	$preJSON->{"printheader"} = $self->title();
	$preJSON->{"viewport"}->{"span"}->{"lat"} = "0.089989";
	$preJSON->{"viewport"}->{"span"}->{"lng"} = "0.107881";
	$preJSON->{"viewport"}->{"center"}->{"lat"} = $self->latitude();
	$preJSON->{"viewport"}->{"center"}->{"lng"} = $self->longitude();
	$preJSON->{"url"} = "/maps?v=1&q=" . 
				uri_escape($self->title()) . "&ie=UTF8";
	$preJSON->{"title"} = $self->title();

	# Render the data structure to a JSON string and return it
	return $json->objToJson($preJSON);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geo::Google::Location - A geographical point

=head1 SYNOPSIS

  use Geo::Google::Location;
  # you shouldn't need to construct these yourself,
  # have a Geo::Google object do it for you. 

=head1 DESCRIPTION

=head1 OBJECT METHODS

Geo::Google::Location objects provide the following accessor methods

 Method      Description
 ------      -----------
 icon        an icon to use when drawing this point.
 id          a unique identifier for this point.
 infostyle   determines how a pop-up info window callout for a plotted point is displayed in Google Maps or Google Earth
 latitude    latitude of the point, to hundred-thousandth degree precision.
 lines       a few lines describing the point, useful as a label
 longitude   longitude of the point, to hundred-thousandth degree precision.
 title       a concise description of the point.
 toXML       a method that renders the point in XML format for use in 
             Google Earth KML files.
 toJSON	     a method that renders the point in JSON format for use
             with the Google Maps API.

=head1 SEE ALSO

L<Geo::Google>

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>, Michael Trowbridge 
E<lt>michael.a.trowbridge@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2007 Allen Day.  All rights
reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
