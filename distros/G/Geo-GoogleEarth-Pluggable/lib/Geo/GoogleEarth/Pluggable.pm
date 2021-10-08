package Geo::GoogleEarth::Pluggable;
use strict;
use warnings;
use base qw{Geo::GoogleEarth::Pluggable::Folder}; 
use XML::LibXML::LazyBuilder qw{DOM E};
use Archive::Zip qw{COMPRESSION_DEFLATED};
use IO::Scalar qw{};

our $VERSION='0.17';

=head1 NAME

Geo::GoogleEarth::Pluggable - Generates GoogleEarth Documents

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Geo::GoogleEarth::Pluggable is a Perl object oriented interface that allows for the creation of XML documents that can be used with Google Earth.

Geo::GoogleEarth::Pluggable (aka Document) is a L<Geo::GoogleEarth::Pluggable::Folder> with a render method.

=head2 Object Inheritance Graph

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

=head2 Constructors that append to the parent folder object

Folder, NetworkLink, Point, LineString, LinearRing

=head2 Constructors that return objects for future use

LookAt(), Style(), StyleMap()

=head2 Wrappers (what makes it easy)

Style => IconStyle, LineStyle, PolyStyle, LabelStyle, ListStyle

Point => MultiPoint

=head1 USAGE

This is all of the code you need to generate a complete Google Earth document.

  use Geo::GoogleEarth::Pluggable;
  my $document=Geo::GoogleEarth::Pluggable->new;
  $document->Point(name=>"White House", lat=>38.897337, lon=>-77.036503);
  print $document->render;

=head1 CONSTRUCTOR

=head2 new

  my $document=Geo::GoogleEarth::Pluggable->new(name=>"My Name");

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$folder->type;

=cut

sub type {"Document"};

=head2 document

Returns the document object.

All objects know to which document they belong even the document itself!

=cut

sub document {shift};

=head2 render

Returns an XML document with an XML declaration and a root name of "Document"

  print $document->render;

=cut

sub render {
  my $self=shift;
  my $d = DOM(E(kml=>{$self->xmlns}, $self->node));
  return $d->toString;
}

=head2 archive

Returns a KMZ formatted Zipped archive of the XML document

  print $document->archive;

=cut

sub archive {
  my $self=shift;
  my $azip=Archive::Zip->new;
  my $member=$azip->addString($self->render, "doc.kml");
  $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
  #$member->desiredCompressionLevel(9); #RT60563, RT54827

  my $archive=q{};
  my $iosh=IO::Scalar->new( \$archive );
  $azip->writeToFileHandle($iosh);
  $iosh->close;
  return $archive;
}

=head2 xmlns

Add or update a namespace

  $document->xmlns->{"namespace"}=$url;

Delete a namespace

  delete($document->xmlns->{"xmlns:gx"});

Replace all namespaces

  $document->{"xmlns"}={namespace=>$url};

Reset to default namespaces

  delete($document->{"xmlns"});

=cut

sub xmlns {
  my $self=shift;
  unless (defined($self->{'xmlns'})) {
    $self->{'xmlns'}={
            'xmlns'      => "http://www.opengis.net/kml/2.2",
            'xmlns:gx'   => "http://www.google.com/kml/ext/2.2",
            'xmlns:kml'  => "http://www.opengis.net/kml/2.2",
            'xmlns:atom' => "http://www.w3.org/2005/Atom",
                     };
  }
  return wantarray ? %{$self->{'xmlns'}} : $self->{'xmlns'};
}

=head2 nextId

This method is in the document since all Styles and StyleMaps are in the document not folders.

  my $id=$document->nextId($type); #$type in "Style" or "StyleMap"

=cut

sub nextId {
  my $self=shift;
  my $type=shift || "Unknown";
  $self->{"nextId"}=0 unless defined $self->{"nextId"};
  return sprintf("%s-%s-%s", $type, "perl", $self->{"nextId"}++);
}

=head2 header, header_kml

Returns a header appropriate for a web application

  Content-type: application/vnd.google-earth.kml+xml
  Content-Disposition: attachment; filename=filename.xls

  $document->header                                                       #embedded in browser
  $document->header(filename=>"filename.xls")                             #download prompt
  $document->header(content_type=>"application/vnd.google-earth.kml+xml") #default content type

=cut

*header_kml=\&header;

sub header {
  my $self=shift;
  my %data=@_;
     $data{"content_type"}="application/vnd.google-earth.kml+xml"
       unless defined $data{"content_type"};
  my $header=sprintf("Content-type: %s\n", $data{"content_type"});
     $header.=sprintf(qq{Content-Disposition: attachment; filename="%s";\n},
                         $data{"filename"}) if defined $data{"filename"};
     $header.="\n";
  return $header;
}

=head2 header_kmz

Returns a header appropriate for a web application

  Content-type: application/vnd.google-earth.kml+xml
  Content-Disposition: attachment; filename=filename.xls

  $document->header_kmz                                                   #embedded in browser
  $document->header_kmz(filename=>"filename.xls")                         #download prompt
  $document->header_kmz(content_type=>"application/vnd.google-earth.kmz") #default content type

=cut

sub header_kmz {
  my $self=shift;
  my %data=@_;
  $data{"content_type"}||="application/vnd.google-earth.kmz";
  return $self->header(%data);
}

=head1 TODO

=over

=item Support for default Polygon and Line styles that are nicer than GoogleEarth's

=item Support for DateTime object in the constructor that is promoted to the LookAt object.

=item Create a L<GPS::Point> plugin (Promote tag as name and datetime to LookAt)

=back

=head1 BUGS

Please log on RT and send to the geo-perl email list.

=head1 LIMITATIONS

=head2 Not So Pretty XML

The XML produced by L<XML::LibXML> is not "pretty".  If you need pretty XML you must pass the output through xmllint or a simular product.

For example: 

  perl -MGeo::GoogleEarth::Pluggable -e "print Geo::GoogleEarth::Pluggable->new->render" | xmllint --format -

=head2 Write Only

This package can only write KML and KMZ files.  However, if you need to read KML files, please see the L<Geo::KML> package's C<from> method.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis (mrdvt92)
  CPAN ID: MRDVT

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::KML>, L<XML::LibXML>, L<XML::LibXML::LazyBuilder>, L<Archive::Zip>, L<IO::Scalar>

=cut

1;
