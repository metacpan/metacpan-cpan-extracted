# NAME

Geo::GoogleEarth::Pluggable::Plugin::AsGeoJSON - PostgreSQL ST\_AsGeoJSON plugin for Geo::GoogleEarth::Pluggable

# SYNOPSIS

    use Geo::GoogleEarth::Pluggable;
    use Geo::GoogleEarth::Pluggable::Plugin::AsGeoJSON; #will be runtime loaded
    my $document = Geo::GoogleEarth::Pluggable->new;
    my $object   = $document->AsGeoJSON(name        => $text,
                                        description => $html,
                                        json        => $json_string,
                                        style       => $style,
                                       );

# DESCRIPTION

Parses the string as returned from the PostgreSQL ST\_AsGeoJSON() function as Google Earth compatible objects.

# USAGE

    use DBIx::Array::Connect 0.06; #path
    use Geo::GoogleEarth::Pluggable 0.16; #Polygon
    my $document = Geo::GoogleEarth::Pluggable->new;
    my $database = DBIx::Array::Connect->new->connect('gis');
    my @gisdata  = $database->sqlarrayhash(&gis_data_sql);
    
    foreach my $row (@gisdata) {
      $document->AsGeoJSON(%$row);
    }
    
    print $document->render;
    
    sub gis_data_sql {
      return qq{
                 SELECT 'Point'                                                          AS "name", 
                        ST_AsGeoJSON(ST_GeomFromText('POINT(-77.38670068 38.78025536)')) AS "json"
               };
    }

# METHODS

## AsGeoJSON

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

# SEE ALSO

[Geo::GoogleEarth::Pluggable](https://metacpan.org/pod/Geo::GoogleEarth::Pluggable), [JSON::XS](https://metacpan.org/pod/JSON::XS)

# AUTHOR

Michael Davis, mrdvt@cpan.org

# COPYRIGHT AND LICENSE

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
