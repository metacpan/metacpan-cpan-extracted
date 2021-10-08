# NAME

Geo::GoogleEarth::Pluggable - Generates GoogleEarth Documents

# SYNOPSIS

    use Geo::GoogleEarth::Pluggable;
    my $document=Geo::GoogleEarth::Pluggable->new(%data); #is a special Folder...
    my $folder  =$document->Folder(%data);                #isa Geo::GoogleEarth::Pluggable::Folder
    my $point   =$document->Point(%data);                 #isa Geo::GoogleEarth::Pluggable::Point
    my $netlink =$document->NetworkLink(%data);           #isa Geo::GoogleEarth::Pluggable::NetworkLink
    my $lookat  =$document->LookAt(%data);                #isa Geo::GoogleEarth::Pluggable::LookAt
    my $style   =$document->Style(%data);                 #isa Geo::GoogleEarth::Pluggable::Style
    print $document->render;

KML CGI Example

    use Geo::GoogleEarth::Pluggable;
    my $document=Geo::GoogleEarth::Pluggable->new(name=>"KML Document");
    print $document->header,
          $document->render;

KMZ CGI Example

    use Geo::GoogleEarth::Pluggable;
    my $document=Geo::GoogleEarth::Pluggable->new(name=>"KMZ Document");
    print $document->header_kmz,
          $document->archive;

# DESCRIPTION

Geo::GoogleEarth::Pluggable is a Perl object oriented interface that allows for the creation of XML documents that can be used with Google Earth.

Geo::GoogleEarth::Pluggable (aka Document) is a [Geo::GoogleEarth::Pluggable::Folder](https://metacpan.org/pod/Geo::GoogleEarth::Pluggable::Folder) with a render method.

## Object Inheritance Graph

    --- Constructor -+- Base --- Folder    --- Document
                     |        |
                     |        +- Placemark -+- Point
                     |        |             +- LineString
                     |        |             +- LinearRing
                     |        |
                     |        +- StyleBase -+- Style
                     |        |             +- StyleMap
                     |        |
                     |        +- NetworkLink
                     |
                     +- LookAt

## Constructors that append to the parent folder object

Folder, NetworkLink, Point, LineString, LinearRing

## Constructors that return objects for future use

LookAt(), Style(), StyleMap()

## Wrappers (what makes it easy)

Style => IconStyle, LineStyle, PolyStyle, LabelStyle, ListStyle

Point => MultiPoint

# USAGE

This is all of the code you need to generate a complete Google Earth document.

    use Geo::GoogleEarth::Pluggable;
    my $document=Geo::GoogleEarth::Pluggable->new;
    $document->Point(name=>"White House", lat=>38.897337, lon=>-77.036503);
    print $document->render;

# CONSTRUCTOR

## new

    my $document=Geo::GoogleEarth::Pluggable->new(name=>"My Name");

# METHODS

## type

Returns the object type.

    my $type=$folder->type;

## document

Returns the document object.

All objects know to which document they belong even the document itself!

## render

Returns an XML document with an XML declaration and a root name of "Document"

    print $document->render;

## archive

Returns a KMZ formatted Zipped archive of the XML document

    print $document->archive;

## xmlns

Add or update a namespace

    $document->xmlns->{"namespace"}=$url;

Delete a namespace

    delete($document->xmlns->{"xmlns:gx"});

Replace all namespaces

    $document->{"xmlns"}={namespace=>$url};

Reset to default namespaces

    delete($document->{"xmlns"});

## nextId

This method is in the document since all Styles and StyleMaps are in the document not folders.

    my $id=$document->nextId($type); #$type in "Style" or "StyleMap"

## header, header\_kml

Returns a header appropriate for a web application

    Content-type: application/vnd.google-earth.kml+xml
    Content-Disposition: attachment; filename=filename.xls

    $document->header                                                       #embedded in browser
    $document->header(filename=>"filename.xls")                             #download prompt
    $document->header(content_type=>"application/vnd.google-earth.kml+xml") #default content type

## header\_kmz

Returns a header appropriate for a web application

    Content-type: application/vnd.google-earth.kml+xml
    Content-Disposition: attachment; filename=filename.xls

    $document->header_kmz                                                   #embedded in browser
    $document->header_kmz(filename=>"filename.xls")                         #download prompt
    $document->header_kmz(content_type=>"application/vnd.google-earth.kmz") #default content type

# TODO

- Support for default Polygon and Line styles that are nicer than GoogleEarth's
- Support for DateTime object in the constructor that is promoted to the LookAt object.
- Create a [GPS::Point](https://metacpan.org/pod/GPS::Point) plugin (Promote tag as name and datetime to LookAt)

# BUGS

Please log on RT and send to the geo-perl email list.

# LIMITATIONS

## Not So Pretty XML

The XML produced by [XML::LibXML](https://metacpan.org/pod/XML::LibXML) is not "pretty".  If you need pretty XML you must pass the output through xmllint or a simular product.

For example: 

    perl -MGeo::GoogleEarth::Pluggable -e "print Geo::GoogleEarth::Pluggable->new->render" | xmllint --format -

## Write Only

This package can only write KML and KMZ files.  However, if you need to read KML files, please see the [Geo::KML](https://metacpan.org/pod/Geo::KML) package's `from` method.

# SUPPORT

DavisNetworks.com supports all Perl applications including this package.

# AUTHOR

    Michael R. Davis (mrdvt92)
    CPAN ID: MRDVT

# COPYRIGHT

This program is free software licensed under the...

    The BSD License

The full text of the license can be found in the LICENSE file included with this module.

# SEE ALSO

[Geo::KML](https://metacpan.org/pod/Geo::KML), [XML::LibXML](https://metacpan.org/pod/XML::LibXML), [XML::LibXML::LazyBuilder](https://metacpan.org/pod/XML::LibXML::LazyBuilder), [Archive::Zip](https://metacpan.org/pod/Archive::Zip), [IO::Scalar](https://metacpan.org/pod/IO::Scalar)
