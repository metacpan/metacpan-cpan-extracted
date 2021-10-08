package Geo::GoogleEarth::Pluggable::Plugin::AsGeoJSON;
use strict;
use warnings;
use Geo::GoogleEarth::Pluggable 0.16; #for Polygon and MultiPolygon support
use JSON::XS qw{};

our $VERSION = '0.05';
our $PACKAGE=__PACKAGE__;

=head1 NAME

Geo::GoogleEarth::Pluggable::Plugin::AsGeoJSON - PostgreSQL ST_AsGeoJSON plugin for Geo::GoogleEarth::Pluggable

=head1 SYNOPSIS

  use Geo::GoogleEarth::Pluggable;
  use Geo::GoogleEarth::Pluggable::Plugin::AsGeoJSON; #can be runtime loaded
  my $document = Geo::GoogleEarth::Pluggable->new;
  my $object   = $document->AsGeoJSON(name        => $text,
                                      description => $html,
                                      json        => $json_string,
                                      style       => $style,
                                     );

=head1 DESCRIPTION

Parses the string as returned from the PostgreSQL ST_AsGeoJSON() function as Google Earth compatible objects.

=head1 USAGE

  use DBIx::Array::Connect 0.06; #path
  use Geo::GoogleEarth::Pluggable 0.16; #Polygon
  my $document = Geo::GoogleEarth::Pluggable->new;
  my $database = DBIx::Array::Connect->new->connect('gis');

  #Select data from PostgreSQL
  my @gisdata  = $database->sqlarrayhash(&gis_data_sql);

  #Add each row as Google Earth document object
  $document->AsGeoJSON(%$_) foreach @gisdata;

  #Print the Google Earth KML document
  print $document->render;
  
  sub gis_data_sql {
    return qq{
               SELECT 'Clifton, VA'                                                    AS "name", 
                      ST_AsGeoJSON(ST_GeomFromText('POINT(-77.38670068 38.78025536)')) AS "json"
             };
  }

=head1 METHODS

=head2 AsGeoJSON

  $document->AsGeoJSON(
                       name        => $text,            #see Placemark
                       description => $html,
                       json        => $json_string,
                       style       => $style,
                      );

JSON Example: Point

  {
   "type" : "Point",
   "coordinates" : [ -77.38670068, 38.78025536 ]
  }

JSON Example: Polygon

  {
   "type" : "Polygon"
   "coordinates" : [
      [
         [ -77.3883082, 38.7796903 ],
         [ -77.3858487, 38.7791080 ],
         [ -77.3859173, 38.7811742 ],
         [ -77.3859710, 38.7812281 ],
         [ -77.3861322, 38.7814079 ],
         [ -77.3883082, 38.7796903 ] 
      ]
   ],
  }

JSON Example: MultiPolygon

  {
   "type" : "MultiPolygon"
   "coordinates" : [
      [
         [
            [ -77.3883082, 38.7796903 ],
            [ -77.3858487, 38.7791080 ],
            [ -77.3859173, 38.7811742 ],
            [ -77.3859710, 38.7812281 ],
            [ -77.3861322, 38.7814079 ],
            [ -77.3883082, 38.7796903 ] 
         ]
      ],
      [
         [
            [ -77.3857118, 38.7789067 ],
            [ -77.3852328, 38.7769665 ],
            [ -77.3843158, 38.7770731 ],
            [ -77.3850419, 38.7786809 ],
            [ -77.3857118, 38.7789067 ]
         ]
      ]
   ],
  }

=cut

sub AsGeoJSON {
  my $self        = shift; #$self isa Geo::GoogleEarth::Pluggable::Folder object
  my %data        = @_;
  my $json        = delete($data{"json"}) or die("Error: AsGeoJSON requires the json parameter.");
  my $decode      = eval{JSON::XS::decode_json($json)};
  my $error       = $@;
  die(qq{Error: AsGeoJSON json parameter JSON decode failed.  JSON: "$json", Error: "$error"}) if $error;
  die(qq{Error: AsGeoJSON json parameter JSON must be an Object (Hash)}) unless ref($decode) eq "HASH";
  my $type        = $decode->{"type"}        or die(qq{Error: AsGeoJSON json parameter JSON missing "type" value});
  my $coordinates = $decode->{"coordinates"} or die(qq{Error: AsGeoJSON json parameter JSON missing "coordinates" value});
  die(qq{Error: AsGeoJSON json parameter JSON Object "coordinates" must be an Array}) unless ref($coordinates) eq "ARRAY";
  my $name        = $data{"name"} ||= $type;
  my $object;
  if ($type eq "Point") {
    $data{"lon"} = $coordinates->[0];
    $data{"lat"} = $coordinates->[1];
    $data{"alt"} = $coordinates->[2] if  defined($coordinates->[2]);
    $object      = $self->Point(%data);
  } elsif ($type eq "LineString") {
    $object      = $self->LineString(%data, coordinates => $coordinates);
  } elsif ($type eq "Polygon") {
    $object      = $self->Polygon(%data, coordinates => $coordinates);
  } elsif ($type eq "MultiPolygon") {
    $object      = $self->MultiPolygon(%data, coordinates => $coordinates)
  } else {
    warn(qq{Warning: $PACKAGE does not support type "$type".\n});
    $object      = $self->Folder(name => sprintf("%s - Unsupported %s", $data{"name"}, $type));
  }
  return $object;
}

=head1 SEE ALSO

L<Geo::GoogleEarth::Pluggable>, L<JSON::XS>

=head1 AUTHOR

Michael Davis, mrdvt@cpan.org

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
