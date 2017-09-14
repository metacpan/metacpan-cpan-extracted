=pod

=head1 NAME

Geo::OGC::Service::WMTS - Perl extension to create geospatial web map tile services

=head1 SYNOPSIS

The process_request method of this module is called by the
Geo::OGC::Service framework. 

In a psgi script write something like

 use Geo::OGC::Service::WMTS;

 my $ogc = Geo::OGC::Service->new({
 config => '/var/www/etc/OGC-services.conf',
 services => {
        'WFS' => 'Geo::OGC::Service::WFS',
        'WMTS' => 'Geo::OGC::Service::WMTS',
        'WMS' => 'Geo::OGC::Service::WMTS',
        'TMS' => 'Geo::OGC::Service::WMTS',
 }});

 builder {
    mount "/WFS" => $ogc->to_app;
    mount "/WMTS" => $ogc->to_app;
    mount "/TMS" => $ogc->to_app;
    mount "/" => $default;
 };

=head1 DESCRIPTION

This module aims to provide the operations defined by the Open
Geospatial Consortium's Web Map Tile Service standard. Additionally,
this module aims to support WMS used as WMTS and TMS.

This module is designed to be a part of the Geo::OGC::Service framework.

A Geo::OGC::Service::WMTS object is a content providing service object
created by a Geo::OGC::Service object. As described in the
documentation of Geo::OGC::Service a service object is created as a
result of a service request. A Geo::OGC::Service::WMTS object is a
hash reference, which contains keys env, request, plugin, config,
service, and optionally posted, filter, and parameters.

=over

=item env 

The PSGI $env.

=item request 

A Plack::Request object constructed from the $env;

=item plugin 

The plugin object given as an argument to Geo::OGC::Service in its
constructor as a top level attribute or as a service specific
attribute.

=item config 

The configuration for this service as constructed by the
Geo::OGC::Service object.

=item service 

The name of the requested service (WMTS, WMS, or TMS).

=item posted 

A XML::LibXML documentElement of the POSTed XML.

=item filter 

A XML::LibXML documentElement contructed from a filter GET parameter.

=item parameters 

A hash made from Plack::Request->parameters (thus removing its multi
value nature). The keys are all converted to lower case and the values
are decoded to Perl's internal format assuming they are UTF-8.

=back

=head1 CONFIGURATION

The configuration is defined similarly as to other services under
Geo::OGC::Service, either as a file or as a variable in the call to
Geo::OGC::Service->new.

The file must be JSON and either have top level key WMTS, WMS, or TMS
if more than one service is defined. The value of the key must be a
hash, or the name of a key, which has a hash value.

Known top level keys in the hash are 'resource', 'blank', 'debug', and
'TileSets'. TileSets is an array of hashes. The keys of a TileSet hash
are Layers, Format, Resolutions, SRS, BoundingBox, path, and ext.

=head2 PLUGIN

The plugin object can be used to modify the config object in response
time.

A Geo::OGC::Service::WMTS object calls the plugin object's config
method with arguments ($config, $self) before the config is used to
create a response to a GetCapabilities request, and in RESTful service
if layer name is not defined. The config method is not called for each
tile request and thus the configuration should probably have parameter
serve_arbitrary_layers set to true.

A Geo::OGC::Service::WMTS object calls the plugin object's process method
when making the tile if the plugin object exists. The method is given
as argument a hash reference with the following keys:

=over

=item dataset 

The GDAL dataset of the layer, if the layer has a configuration
parameter 'file'.

=item tile 

A Geo::OGC::Service::WMTS::Tile object made from the request. The
extent is from projection, which is deduced from the tilematrixset
parameter.

=item service 

The Geo::OGC::Service::WMTS object.

=item headers 

Currently ['Content-Type' => "image/png"]

=back

=head2 EXPORT

None by default. Package globals include

=over

=item $radius_of_earth_at_equator 

6378137

=item $standard_pixel_size 

0.28/1000

=item $tile_width 

256

=item $tile_height 

256

=item $originShift3857 

Math::Trig::pi * $radius_of_earth_at_equator

=item %projections 

Hash of 'EPSG:nnnn' => {identifier => x, crs => x, extent => {SRS =>
x, minx => x, maxx => x, miny => x, maxy => x}}. Currently contains
EPSG:3857 and EPSG:3067.

=back

=head2 METHODS

=cut

package Geo::OGC::Service::WMTS;

use 5.010000; # say // and //=
use feature "switch";
use Carp;
use File::Basename;
use Modern::Perl;
use JSON;
use Geo::GDAL;
use Cwd;
use Math::Trig;
use HTTP::Date;

use Data::Dumper;
use XML::LibXML::PrettyPrint;

use Geo::OGC::Service;
use vars qw(@ISA);
push @ISA, qw(Geo::OGC::Service::Common);

our $VERSION = '0.07';

our $radius_of_earth_at_equator = 6378137;
our $standard_pixel_size = 0.28 / 1000;
our $tile_width = 256;
our $tile_height = 256;
our $originShift3857 = pi * $radius_of_earth_at_equator;

our %projections = (
    'EPSG:3857' => {
        identifier => 'EPSG:3857',
        crs => 'urn:ogc:def:crs:EPSG:6.3:3857',
        extent => {
            SRS => 'EPSG:3857', 
            minx => -1 * $originShift3857,
            miny => -1 * $originShift3857,
            maxx => $originShift3857,
            maxy => $originShift3857  },
    },
    'EPSG:3067' => {
        identifier => 'ETRS-TM35FIN',
        crs => 'urn:ogc:def:crs:EPSG:6.3:3067',
        extent => { 
            SRS => 'EPSG:3067', 
            # JHS180 liite 1:
            minx => -548576,
            miny => 6291456,
            maxx => 1548576,
            maxy => 8388608 }
    }
);

=pod

=head3 process_request

The entry method into this service. Calls RESTful if there is no
request parameter, otherwise dispatches the call to
WMSGetCapabilities, GetCapabilities, GetTile, GetMap, or FeatureInfo
depending on service and request. If request is not recognized,
returns an error XML with exceptionCode => 'InvalidParameterValue'.

=cut

sub process_request {
    my ($self, $responder) = @_;
    $self->{debug} = $self->{config}{debug};
    if ($self->{debug}) {
        if ($self->{debug} > 2) {
            $self->log($self);
        } elsif ($self->{debug} > 1) {
            $self->log({ service => $self->{service},
                         parameters => $self->{parameters},
                         request => $self->{request} });
        } else {
            $self->log({ service => $self->{service},
                         parameters => $self->{parameters} });
        }
    }
    $self->{responder} = $responder;
    $self->{parameters}{request} //= '';
    my $response;
    for ($self->{parameters}{request}) {
        if ($self->{service} eq 'WMS' and (/^GetCapabilities/ or /^capabilities/)) { $self->WMSGetCapabilities() }
        elsif (/^GetCapabilities/ or /^capabilities/) { $self->GetCapabilities() }
        elsif (/^GetTile/)                         { $response = $self->GetTile() }
        elsif (/^GetMap/)                          { $response = $self->GetMap() }
        elsif (/^FeatureInfo/)                     { $response = $self->FeatureInfo() }
        elsif (/^$/)                               { $response = $self->RESTful() }
        else                                       { 
            $self->error({ exceptionCode => 'InvalidParameterValue',
                           locator => 'request',
                           ExceptionText => "$self->{parameters}{request} is not a known request" }) }
    }
    $self->{responder}->($response) if $response;
}

=pod

=head3 GetCapabilities

Sends a capabilities document according to WMTS standard.

=cut

sub GetCapabilities {
    my ($self) = @_;
    my $config = $self->{config};
    $config = $self->{plugin}->config($config, $self) if $self->{plugin};
    my $writer = Geo::OGC::Service::XMLWriter::Caching->new();
    $writer->open_element(Capabilities => { 
        version => '1.0.0',
        xmlns => "http://www.opengis.net/wmts/1.0",
        'xmlns:ows' => "http://www.opengis.net/ows/1.1",
        'xmlns:xlink' => "http://www.w3.org/1999/xlink",
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xmlns:gml' => "http://www.opengis.net/gml",
        'xsi:schemaLocation' => "http://www.opengis.net/wmts/1.0 ".
            "http://schemas.opengis.net/wmts/1.0/wmtsGetCapabilities_response.xsd",
    });
    $self->DescribeService($writer);
    $writer->open_element('ows:OperationsMetadata');
    for my $operation (qw/GetCapabilities GetTile GetFeatureInfo/) {
        $self->Operation( $writer, $operation, { Get => [ 'ows:AllowedValues' => ['ows:Value' => 'KVP' ] ] } );
    }
    $writer->close_element;
    $writer->open_element(Contents => {});

    my $t_srs = $Geo::GDAL::VERSION >= 2 ? 
        Geo::OSR::SpatialReference->new(EPSG=>4326) : 
        Geo::OSR::SpatialReference->create(EPSG=>4326);

    for my $set (@{$config->{TileSets}}) {
        my $projection = $projections{$set->{SRS}};

        my $bb;
        if ($set->{BoundingBox}) {
            my ($epsg) = $set->{BoundingBox}{SRS} =~ /(\d+)/;
            my $s_srs = $Geo::GDAL::VERSION >= 2 ? 
                Geo::OSR::SpatialReference->new(EPSG => $epsg) :
                Geo::OSR::SpatialReference->create(EPSG => $epsg);
            my $ct = Geo::OSR::CoordinateTransformation->new($s_srs, $t_srs);

            my $x = $set->{BoundingBox};
            #$x = $projection->{extent}; not in s_srs

            my $points = [[$x->{minx}, $x->{miny}],
                          [$x->{maxx}, $x->{maxy}]];

            $ct->TransformPoints($points);

            $bb = [ 'ows:WGS84BoundingBox' => { crs => "urn:ogc:def:crs:OGC:2:84" },
                   [ [ 'ows:LowerCorner' => "$points->[0][0] $points->[0][1]" ],
                     [ 'ows:UpperCorner' => "$points->[1][0] $points->[1][1]" ] ] ];
            
        }

        my ($ext) = $set->{Format} =~ /(\w+)$/;
        my @layer = (
            [ 'ows:Title' => $set->{Title} // $set->{Layers} ],
            [ 'ows:Identifier' => $set->{Layers} ],
            [ 'Style' => { isDefault => 'true' }, [ 'ows:Identifier' => 'default' ] ],
            [ Format => $set->{Format} ],
            [ TileMatrixSetLink => [ TileMatrixSet => $projection->{identifier} ] ]
        );
        push @layer, $bb if $bb;
        push @layer, [ ResourceURL => {
            resourceType => 'tile',
            format => $set->{Format},
            template => "$config->{resource}/$set->{Layers}/{TileMatrix}/{TileCol}/{TileRow}.$ext"
        } ] if $set->{RESTful};
        $writer->element('Layer' => \@layer );
    };
    for my $projection (keys %projections) {
        tile_matrix_set($writer, $projections{$projection}, [0..17]); # GDAL uses the highest value
    }
    $writer->close_element;
    $writer->close_element;
    $writer->stream($self->{responder});
}

=pod

=head3 WMSGetCapabilities

Sends a capabilities document according to WMS standard.

=cut

sub WMSGetCapabilities {
    my ($self) = @_;

    my $config = $self->{config};
    $config = $self->{plugin}->config($config, $self) if $self->{plugin};

    my $writer = Geo::OGC::Service::XMLWriter::Caching->new();

    $writer->open_element(WMT_MS_Capabilities => { version => '1.1.1' });
    $writer->element(Service => [
                         [Name => 'OGC:WMS'],
                         ['Title'],
                         [OnlineResource => {'xmlns:xlink' => "http://www.w3.org/1999/xlink",
                                             'xlink:href' => $config->{resource}}]]);
    $writer->open_element('Capability');
    $writer->element(Request => 
                     [[GetCapabilities => 
                       [[Format => 'application/vnd.ogc.wms_xml'],
                        [DCPType => 
                         [HTTP => 
                          [Get => 
                           [OnlineResource => 
                            {'xmlns:xlink' => "http://www.w3.org/1999/xlink",
                             'xlink:href' => $config->{resource}}]]]]]],
                      [GetMap => 
                       [[Format => 'image/png'],
                        [DCPType => 
                         [HTTP => 
                          [Get => 
                           [OnlineResource => 
                            {'xmlns:xlink' => "http://www.w3.org/1999/xlink",
                             'xlink:href' => $config->{resource}}]]]]]]
                     ]);
    $writer->element(Exception => [Format => 'text/plain']);
    
    for my $set (@{$config->{TileSets}}) {
        my($i0,$i1) = split /\.\./, $set->{Resolutions};

        #my @resolutions = @resolutions_3857[$i0..$i1]; # with this QGIS starts to ask higher resolution tiles
        my @resolutions;
        my $projection = $projections{$set->{SRS}};
        my $extent_width = $projection->{extent}{maxx} - $projection->{extent}{minx};
        for my $i (0..19) {
            $resolutions[$i] = $extent_width/(2**$i * $tile_width);
        }

        my $bb = $set->{BoundingBox}; # with this QGIS does not show tiles at correct locations
        $bb = $projection->{extent};

        $writer->element(VendorSpecificCapabilities => 
                         [TileSet => [[SRS => $set->{SRS}],
                                      [BoundingBox => $bb],
                                      [Resolutions => "@resolutions"],
                                      [Width => $set->{Width} // $tile_width],
                                      [Height => $set->{Height} // $tile_height],
                                      [Format => $set->{Format}],
                                      [Layers => $set->{Layers}],
                                      [Styles => undef]]]);
    }

    $writer->element(UserDefinedSymbolization => 
                     {SupportSLD => 0, UserLayer => 0, UserStyle => 0, RemoteWFS => 0});

    for my $set (@{$config->{TileSets}}) {

        my $projection = $projections{$set->{SRS}};

        my $bb = $set->{BoundingBox}; # with this QGIS does not show tiles at correct locations
        $bb = $projection->{extent};

        $writer->element(Layer => [[Title => 'TileCache Layers'],
                                   [Layer => {queryable => 0, opaque => 0, cascaded => 1}, 
                                    [[Name => $set->{Layers}],
                                     [Title => $set->{Layers}],
                                     [SRS => $set->{SRS}],
                                     [Format => $set->{Format}],
                                     [BoundingBox => $bb]
                                    ]]
                         ]);
    }

    $writer->close_element;
    $writer->close_element;
    $writer->stream($self->{responder});
}

=pod

=head3 GetMap

Serves the tile request if WMS is used.

Sends the requested tile based on parameters BBOX, LAYERS, and SRS.

The tiles should be in a tile map resource type of directory structure
(z/y/x.png). The value of the 'path' key in the TileSet config element
should point to the directory.

=cut

sub GetMap {
    my ($self) = @_;
    for my $param (qw/bbox layers srs/) {
        unless (defined $self->{parameters}{$param}) {
            $self->error({ exceptionCode => 'MissingParameterValue',
                           locator => uc($param) });
            return;
        }
    }
    my $set;
    for my $s (@{$self->{config}{TileSets}}) {
        if ($s->{Layers} eq $self->{parameters}{layers}) {
            $set = $s;
            last;
        }
    }
    unless ($set) {
        $self->error({ exceptionCode => 'InvalidParameterValue',
                       locator => 'LAYERS' });
        return;
    }

    my $projection = $projections{$self->{parameters}{srs}};

    unless ($projection) {
        my @supported = sort keys %projections;
        return $self->error({ exceptionCode => 'InvalidParameterValue',
                              locator => 'SRS',
                              ExceptionText => "$self->{parameters}{srs} is not currently supported." });
    }

    # the assumption is that bbox defines a tile and we need to find the tile
    # if the bbox does not define a tile, then we fail because this is not a WMS
    # the bbox does not define a tile if we do not find a matching matrix
    my $extent_width = $projection->{extent}{maxx} - $projection->{extent}{minx};
    my $extent_height = $projection->{extent}{maxy} - $projection->{extent}{miny};
    my @bbox = split /,/, $self->{parameters}{bbox}; # minx, miny, maxx, maxy
    my $width = $bbox[2] - $bbox[0];
    my $height = $bbox[3] - $bbox[1];
    my $matrix = 0;
    my $two_to_matrix = 1;
    while (abs($two_to_matrix * $width - $extent_width) > 10 && $matrix < 30) {
        ++$matrix;
        $two_to_matrix *= 2;
    }
    return $self->error({ exceptionCode => 'InvalidParameterValue',
                          locator => 'BBOX',
                          ExceptionText => "This is a tile service. The BBOX must define a tile." }) if $matrix >= 30;
    
    my $col = $two_to_matrix * ($bbox[0] - $projection->{extent}{minx}) / $extent_width;
    $col = int( POSIX::floor($col) + 0.5);
    my $row = $two_to_matrix * ($projection->{extent}{maxy} - $bbox[3]) / $extent_height;
    $row = int( POSIX::floor($row) + 0.5);

    ($set->{ext}) = $set->{Format} =~ /(\w+)$/;

    if ($set->{file}) {
        $self->{parameters}{tilematrix} = $matrix;
        $self->{parameters}{tilecol} = $col;
        $self->{parameters}{tilerow} = $row;
        return $self->make_tile($set);
    }

    $row = $two_to_matrix - $row - 1;
    return $self->tile("$set->{path}/$matrix/$col/$row.$set->{ext}", $set->{Format});
}

=pod

=head3 GetTile

Serves the tile request if WMTS is used.

Sends the requested tile based on parameters Layer, Tilerow, Tilecol,
Tilematrix, Tilematrixset, and Format.

The tile is served from a tile map directory or it is made on the fly
from a GDAL data source (the value of the 'file' key in the TileSet).
In addition, processing may be applied to the data source (the
'processing' key). The processing may be one of those implemented in
GDAL.

Using the 'file' keyword requires GDAL 2.1.

Keyword RESTful (0/1) controls the ResourceURL element in the
capabilities XML. Default is false.

=cut

sub GetTile {
    my ($self) = @_;
    for my $param (qw/layer tilerow tilecol tilematrix tilematrixset format/) {
        return $self->error({ exceptionCode => 'MissingParameterValue',
                              locator => $param }) unless $self->{parameters}{$param};
    }
    ($self->{parameters}{ext}) = $self->{parameters}{format} =~ /(\w+)$/;

    if ($self->{config}{serve_arbitrary_layers}) {
        # SRS from tilematrixset
        for my $srs (keys %projections) {
            if ($projections{$srs}{identifier} eq $self->{parameters}{tilematrixset}) {
                return $self->make_tile({SRS => $srs});
            }
        }
        return $self->error({ exceptionCode => 'UnknownParameterValue',
                              locator => 'tilematrixset' });
    }

    my $layer;
    for my $s (@{$self->{config}{TileSets}}) {
        if ($s->{Layers} eq $self->{parameters}{layer}) {
            $layer = $s;
            last;
        }
    }
    return $self->error({ exceptionCode => 'InvalidParameterValue',
                          locator => 'layer' }) unless defined $layer;

    ($layer->{ext}) = $layer->{Format} =~ /(\w+)$/;

    return $self->make_tile($layer) if $layer->{file};
    
    my $matrix = $self->{parameters}{tilematrix};
    my $col = $self->{parameters}{tilecol};
    my $row = 2**$matrix - ($self->{parameters}{tilerow} + 1);
    my $ext = $self->{parameters}{ext} // $layer->{ext};
    return $self->tile("$layer->{path}/$matrix/$col/$row.$ext", $layer->{Format});

}

=pod

=head3 RESTful

RESTful service. The URL should have the form
<service>/layer/<TileMatrixSet>/<TileMatrix>/<TileCol>/<TileRow>.<ext>.
TileMatrixSet is optional. Compare this to the template in
capabilities.

Sends TileMapService response if the layer is not in the URL, TileMap
response if the layer is in the URL but zoom, row, and col are not, or
the requested tile based on layer, zoom, row, and column in the URL.

=cut

sub RESTful {
    my ($self) = @_;
    my $path = $self->{env}{PATH_INFO};
    $self->log({ path => $path }) if $self->{debug};
    my ($layer_name) = $path =~ /^\/(\w+)/;
    return $self->tilemaps unless defined $layer_name;
    my $layer;
    for my $s (@{$self->{config}{TileSets}}) {
        $layer = $s, last if $s->{Layers} eq $layer_name;
    }
    return $self->error({ exceptionCode => 'InvalidParameterValue',
                          locator => 'layer' }) unless defined $layer;
    $path =~ s/^\/(\w+)//;
    my ($matrix, $col, $row, $ext) = $path =~ /^\/(\w+)\/(\w+)\/(\w+)\.(\w+)$/;
    unless (defined $matrix) {
        ($self->{parameters}{tilematrixset}, $matrix, $col, $row, $ext) = 
            $path =~ /^\/([\w\:]+)\/(\w+)\/(\w+)\/(\w+)\.(\w+)$/;
    }
    return $self->tilemapresource($layer) unless defined $matrix;

    if ($layer->{file}) {
        $self->{parameters}{ext} = $ext;
        $self->{parameters}{format} = "image/$ext";
        $self->{parameters}{layer} = $layer_name;
        $self->{parameters}{tilematrix} = $matrix;
        $self->{parameters}{tilecol} = $col;
        $self->{parameters}{tilerow} = 2**$matrix-($row+1);
        return $self->make_tile($layer);
    }

    $row = 2**$matrix - ($row + 1) if $self->{service} eq 'WMTS';

    return $self->tile("$layer->{path}/$matrix/$col/$row.$layer->{ext}", $layer->{Format});
}

=pod

=head3 FeatureInfo

Not yet implemented.

=cut

sub FeatureInfo {
    my ($self) = @_;
    return error_403();
}

sub make_tile {
    my ($self, $layer) = @_;

    #$self->log($self->{parameters});

    return $self->error({ exceptionCode => 'ResourceNotFound',
                          ExceptionText => "File resources are not supported by this GDAL version." })
        unless Geo::GDAL::Dataset->can('Translate');
        
    my $ds;
    $ds = Geo::GDAL::Open($layer->{file}) if $layer->{file};

    if (0) {
        # TODO: SRS transformation 
        # if our source data ($ds) 
        # is not in the SRS that is requested (*should* be in $self->{parameters}{SRS})
        my $srs_s = $ds->SpatialReference;
        
        my ($epsg_t) = $layer->{SRS} =~ /(\d+)/;
        my $srs_t = $Geo::GDAL::VERSION >= 2 ? 
            Geo::OSR::SpatialReference->new(EPSG => $epsg_t) :
            Geo::OSR::SpatialReference->create(EPSG => $epsg_t);
        
        if (!$srs_s->IsSame($srs_t)) {
            $ds = $ds->Warp('/vsimem/w.png', );
        }
    }

    my $projection = $projections{$layer->{SRS}};
        
    my $tile = Geo::OGC::Service::WMTS::Tile->new($projection->{extent}, $self->{parameters});

    eval {

        my @headers = ('Content-Type' => "image/png");
        
        if ($self->{plugin}) {
            $ds = $self->{plugin}->process({dataset => $ds, tile => $tile, service => $self, headers => \@headers});
            
        } elsif ($layer->{processing}) {
            $tile->expand(2);
            $ds = $ds->Translate( "/vsimem/tmp.tiff", ['-of' => 'GTiff', '-r' => 'bilinear' , 
                                                       '-outsize' , $tile->tile,
                                                       '-projwin', $tile->projwin,
                                                       '-a_ullr', $tile->projwin] );
            my $z = $layer->{zFactor} // 1;
            $ds = $ds->DEMProcessing("/vsimem/tmp2.tiff", $layer->{processing}, undef, { of => 'GTiff', z => $z });
            $tile->expand(-2);
        }
        
        my $writer = $self->{responder}->([200, \@headers]);
            
        $ds->Translate($writer, ['-of' => 'PNG', '-r' => 'nearest', 
                                 '-outsize' , $tile->tile,
                                 '-projwin', $tile->projwin,
                                 '-a_ullr', $tile->projwin
                       ]);
    };
        
    if ($@) {
        # subsystems should use newline in error messages
        # so we can report the error location to stderr but not to the client
        print STDERR $@;
        my $gdal_error = Geo::GDAL->errstr;
        say STDERR $gdal_error if $gdal_error;
        my @error = split /\n/, $@;
        while (@error && $error[$#error] =~ /^\s/) {
            pop @error; # remove the code location
        }
        return $self->error({ exceptionCode => 'ResourceNotFound',
                              ExceptionText => join("\n", @error) });
    }
        
    return undef;
}

sub tile {
    my ($self, $tile, $content_type) = @_;
    #print STDERR "tile: $tile, $content_type\n";
    $tile = $self->{config}{blank} unless -r $tile;
    open my $fh, "<:raw", $tile or return error_403();
    my @stat = stat $tile;
    Plack::Util::set_io_path($fh, Cwd::realpath($tile));
    return [ 200, [
                 'Content-Type'   => $content_type,
                 'Content-Length' => $stat[7],
                 'Last-Modified'  => HTTP::Date::time2str( $stat[9] )
             ],
             $fh,
        ];
}

sub tile_matrix_set {
    my ($writer, $projection, $tile_matrix_set) = @_;
    $writer->open_element('TileMatrixSet');
    $writer->element('ows:Identifier' => $projection->{identifier});
    $writer->element(BoundingBox => { crs =>  $projection->{crs} },
                     [ ['ows:LowerCorner' => $projection->{extent}{minx}.' '.$projection->{extent}{miny} ],
                       ['ows:UpperCorner' => $projection->{extent}{maxx}.' '.$projection->{extent}{maxy} ] ]);
    $writer->element('ows:SupportedCRS' => { crs =>  $projection->{crs} }, $projection->{crs});
    my $extent_width = $projection->{extent}{maxx} - $projection->{extent}{minx};
    for my $tile_matrix (@$tile_matrix_set) {
        my $matrix_width = 2**$tile_matrix;
        my $matrix_height = 2**$tile_matrix;
        $writer->element(TileMatrix => 
                         [ [ 'ows:Identifier' => $tile_matrix ],
                           [ ScaleDenominator => 
                             $extent_width / 
                             ($matrix_width * $tile_width) / 
                             $standard_pixel_size ],
                           [ TopLeftCorner => $projection->{extent}{minx}.' '.$projection->{extent}{maxy} ],
                           [ TileWidth => $tile_width ],
                           [ TileHeight => $tile_height ],
                           [ MatrixWidth => $matrix_width ],
                           [ MatrixHeight => $matrix_height ] ]);
    }
    $writer->close_element();
}

sub tilemaps {
    my ($self) = @_;
    my $config = $self->{config};
    $config = $self->{plugin}->config($config, $self) if $self->{plugin};
    my $writer = Geo::OGC::Service::XMLWriter::Caching->new();
    $writer->open_element(TileMapService => { version => "1.0.0", 
                                              tilemapservice => "http://tms.osgeo.org/1.0.0" });
    $writer->open_element(TileMaps => {});
    for my $layer (@{$config->{TileSets}}) {
        $writer->element(TileMap => {href => $config->{resource}.'/'.$layer->{Layers}, 
                                     srs => $layer->{SRS}, 
                                     title => $layer->{Title}, 
                                     profile => 'none'});
    }
    $writer->close_element;
    $writer->close_element;
    $writer->stream($self->{responder});
    return undef;
}

sub tilemapresource {
    my ($self, $layer) = @_;
    my $writer = Geo::OGC::Service::XMLWriter::Caching->new();
    $writer->open_element(TileMap => { version => "1.0.0", 
                                       tilemapservice => "http://tms.osgeo.org/1.0.0" });
    $writer->element(Title => $layer->{Title} // $layer->{Layers});
    $writer->element(Abstract => $layer->{Abstract} // '');
    $writer->element(SRS => $layer->{SRS} // 'EPSG:3857');
    $writer->element(BoundingBox => $layer->{BoundingBox});
    $writer->element(Origin => {x => $layer->{BoundingBox}{minx}, y => $layer->{BoundingBox}{miny}});
    my ($ext) = $layer->{Format} =~ /(\w+)$/;
    $writer->element(TileFormat => { width => $layer->{Width} // $tile_width, 
                                     height => $layer->{Height} // $tile_height, 
                                     'mime-type' => $layer->{Format}, 
                                     extension => $ext });
    my @sets;
    my ($n, $m) = $layer->{Resolutions} =~ /(\d+)\.\.(\d+)$/;
    my $projection = $projections{$layer->{SRS}};
    my @resolutions;
    my $extent_width = $projection->{extent}{maxx} - $projection->{extent}{minx};
    for my $i (0..19) {
        $resolutions[$i] = $extent_width/(2**$i * $tile_width);
    }
    for my $i ($n..$m) {
        push @sets, [TileSet => {href=>$i, order=>$i, 'units-per-pixel'=>$resolutions[$i]}];
    }
    $writer->element(TileSets => {profile => "mercator"}, \@sets);
    $writer->close_element;
    $writer->stream($self->{responder});
    return undef;
}

sub error {
    my ($self, $msg) = @_;
    if (!$msg->{debug}) {
        Geo::OGC::Service::error($self->{responder}, $msg);
        return undef;
    } else {
        my $json = JSON->new;
        $json->allow_blessed([1]);
        my $writer = $self->{responder}->([200, [ 'Content-Type' => 'application/json',
                                                  'Content-Encoding' => 'UTF-8' ]]);
        $writer->write($json->encode($msg->{debug}));
        $writer->close;
    }
}

sub log {
    my ($self, $msg) = @_;
    say STDERR Dumper($msg);
}

=pod

=head3 Geo::OGC::Service::WMTS::Tile

A class for the dimensions of the tile to be sent to the
client. Methods are

=over

=item Geo::OGC::Service::WMTS::Tile->new($extent, $parameters) 

$extent should be a reference to a hash of minx, maxx, miny, and
maxy. $parameters should be a reference to a has of tilematrix,
tilecol, and tilerow.

=item size 

The width and height of the tile in pixels. These come originally from
the Geo::OGC::Service::WMTS globals.

=item projwin 

An array (minx maxy maxx miny).

=item extent 

A Geo::GDAL::Extent object of the tile extent.

=item expand($pixels) 

Expand (or shrink) the tile $pixels pixels. Useful for some processing
tasks.

=back

=cut

{
    package Geo::OGC::Service::WMTS::Tile;
    sub new {
        my ($class, $extent, $parameters) = @_;
        my $self = []; # tile_width tile_height minx maxy maxx miny pixel_width pixel_height
                       #     0          1        2    3    4    5        6           7
        $self->[0] = $Geo::OGC::Service::WMTS::tile_width;
        $self->[1] = $Geo::OGC::Service::WMTS::tile_height;
        my $extent_width = $extent->{maxx} - $extent->{minx};
        my $extent_height = $extent->{maxy} - $extent->{miny};
        my $matrix_width = 2**$parameters->{tilematrix};
        my $width = $extent_width/$matrix_width;
        my $height = $extent_height/$matrix_width;
        $self->[2] = $extent->{minx} + $parameters->{tilecol} * $width;
        $self->[3] = $extent->{maxy} - $parameters->{tilerow} * $height;
        $self->[4] = $extent->{minx} + ($parameters->{tilecol}+1) * $width;
        $self->[5] = $extent->{maxy} - ($parameters->{tilerow}+1) * $height;
        $self->[6] = $width / $self->[0];
        $self->[7] = $height / $self->[1];
        bless $self, $class;
    }
    sub tile {
        my ($self) = @_;
        return @{$self}[0..1];
    }
    *size = *tile;
    sub projwin {
        my ($self) = @_;
        return @{$self}[2..5];
    }
    sub extent {
        my ($self) = @_;
        return Geo::GDAL::Extent->new($self->[2], $self->[5], $self->[4], $self->[3]);
    }
    sub expand {
        my ($self, $pixels) = @_;
        $self->[0] += 2*$pixels;
        $self->[1] += 2*$pixels;
        $self->[2] -= $self->[6]*$pixels;
        $self->[3] += $self->[7]*$pixels;
        $self->[4] += $self->[6]*$pixels; 
        $self->[5] -= $self->[7]*$pixels;
    }
}

sub error_403 {
    [403, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['forbidden']];
}

1;
__END__

=head1 LIMITATIONS

Currently only EPSG 3067 (ETRS-TM35FIN) and 3857 (Google Mercator) are
supported. To support other tile matrix sets add them to
%Geo::OGC::Service::WMTS::projections.

=head1 SEE ALSO

Discuss this module on the Geo-perl email list.

L<https://list.hut.fi/mailman/listinfo/geo-perl>

For the WMTS standard see 

L<http://www.opengeospatial.org/standards/wmts>

=head1 REPOSITORY

L<https://github.com/ajolma/Geo-OGC-Service-WMTS>

=head1 AUTHOR

Ari Jolma, E<lt>ari.jolma at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015- by Ari Jolma

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
