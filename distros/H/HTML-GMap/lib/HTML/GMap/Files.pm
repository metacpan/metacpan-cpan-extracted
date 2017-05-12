package HTML::GMap::Files;

our $VERSION = '0.06';

# $Id: Files.pm,v 1.13 2007/09/19 01:49:12 canaran Exp $

use warnings;
use strict;

use Carp;
use Storable;

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;

    eval {
        exists $params{temp_dir} or croak("A temp_dir param is required!");
        $self->temp_dir($params{temp_dir});
    };

    $self->croak($@) if $@;

    $self->create_files;

    return $self;
}

sub create_files {
    my ($self) = @_;

    my $files_ref = $self->files;
    my $temp_dir  = $self->temp_dir;

    foreach my $file_name (keys %$files_ref) {
        my $file_content = $files_ref->{$file_name}->{content};
        my $file_type    = $files_ref->{$file_name}->{type};
        
        if ($file_type eq 'binary') {
            $file_content =~ s/\n//g;
            
            my $binary_content = pack('H*', $file_content);
            
            open(OUT, ">$temp_dir/$file_name")
              or croak("Cannot write file ($temp_dir/$file_name): $!");
            binmode OUT;
            
            print OUT $binary_content;

            close OUT;
        }    
        
        else {
            open(OUT, ">$temp_dir/$file_name")
              or croak("Cannot write file ($temp_dir/$file_name): $!");

            $file_content =~ s/^\s+//;
            $file_content =~ s/\s+$/\n/;

            print OUT $file_content;

            close OUT;
        }    


    }

    return 1;
}

sub temp_dir {
    my ($self, $value) = @_;

    $self->{temp_dir} = $value if @_ > 1;

    return $self->{temp_dir};
}

sub files {
    my ($self) = @_;

    my %files;

    
    $files{'gmap-main.css'}{'type'}    = 'ascii';
    $files{'gmap-main.css'}{'content'} = <<'CONTENT';
/*
Author: Payan Canaran (pcanaran@cpan.org)
Copyright 2006-2007 Cold Spring Harbor Laboratory
$Id: Files.pm,v 1.13 2007/09/19 01:49:12 canaran Exp $
*/

body {
    text-align: center;
    font-family: arial;
}    

th {
  font-size: 12px;
}

td {
  font-size: 12px;
  vertical-align: top;
}

table.container {
  border: 1px dashed #333;
  background-color: #F5F5DC;
  text-align: left;
  font-size: 13px;
}

div.sub_header {
  padding: 4px;
  font-size: 14px;
  font-weight: bold;
}

div.status {
  padding: 4px;
  width: 250px;
}

div.filter {
  padding: 4px;
  width: 240px;
}

div.messages {
 padding: 4px;
 width: 250px;
 overflow: auto;
}

div.details_info {
  padding: 4px;
  height: 110px;
  width: 240px;
  overflow: auto;
}

div.legend_info {
  padding: 4px;
  height: 490px;
  width: 180px;
  font-weight: bold;
  overflow: auto;
}

div.float_right {
  clear: right;
  display: inline;
}

div.hidden {
  visibility: hidden;
  display: inline;
}

div.visible {
  visibility: visible;
  display: inline;
}

font.bold {
  font-weight: bold;
}

CONTENT
    
    $files{'gmap-main.html'}{'type'}    = 'ascii';
    $files{'gmap-main.html'}{'content'} = <<'CONTENT';
<!--
Author: Payan Canaran (pcanaran@cpan.org)
Copyright 2006-2007 Cold Spring Harbor Laboratory
$Id: Files.pm,v 1.13 2007/09/19 01:49:12 canaran Exp $
-->

[% cgi_header %]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml">

<head>
    <link rel="stylesheet" type="text/css" href="[% gmap_main_css_file_eq %]" />
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>[% page_title %]</title>

    <style type="text/css">
        v\:* {
          behavior:url(#default#VML);
        }
    </style>
</head>

<body>
    [% header %]

    <h1>[% page_title %]</h1>

    <table align="center" class="container">
        <tr>
            <td>
                <div class="sub_header">Legend: </div>
                <div id="legend" class="legend_info"></div>
                <p/>
                <div id="legend_message"></div>
            </td>
        
            <td>
                <div id="map" style="height: [% image_height_pix %]px; width: [% image_width_pix %]px">
                Loading map ...
                </div>
            </td>

            <td>
                <div class="sub_header">Status: </div>
                <div id="status" class="status">Initializing ...</div>

                <div>
                    <form id="filter">
                    <div class="sub_header">Filter: </div>

                    <div class="filter">
                        <table width="100%">
                            [% FOREACH field = param_fields_with_values %]
                            <tr>
                                <!-- Param [% field.name %] -->
                                <td align="left">
                                    <font class="bold">[% field.display %]:</font>
                                </td>
                                <td align="right">
                                    <select id="[% field.name %]" name="[% field.name %]">
                                        [% FOREACH value = field.values %]
                                        <option value="[% value.param %]">[% value.display %]</option>
                                        [% END %]
                                    </select>
                                </td>
                            [% END %]
                            </tr>
                        </table>
                   
                        <div id="cluster_slices_group" class="visible">
                            [% IF display_cluster_slices %]
                            <table width="100%">
                                <tr>
                                    <td align="left">
                                        <input id="cluster_slices" type="checkbox" name="cluster_slices"></input>
                                        Cluster rare values:
                                    </td>
                                </tr>
                                <tr>
                                    <td align="right">
                                        (less than
                                        <input id="cluster_slices_value" type="text" name="cluster_slices_value" size="2" value="2">
                                        <select id="cluster_slices_by" name="cluster_slices_by">
                                            <option value="percent" selected="1">%</option>
                                            <option value="count">pt</option>
                                        </select>
                                        per tile)
                                    </td>
                                </tr>
                            </table>
                            [% END %]
                        </div>
    
                        <div>
                        <table width="100%">
                            <tr>
                                <td align="right">
                                    <input type="button" name="Filter" value="Filter" onClick="doRefresh()"/>
                                </td>
                            </tr>       
                        </table>    
                        </div>
                    </div>
                    </form>    
                </div>

                <div>
                    <div class="sub_header">Details: </div>
                    <div id="details" class="details_info"></div>
                </div>

                <div>
                    <div class="sub_header">Messages: </div>
                    <div id="messages" class="messages">[% messages %]</div>            
                </div>
            </td>
        </tr>
    </table>
    
    <div id="debug">
    </div>

    <!-- Execute scripts here (1/2) -->
    <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=[% gmap_key %]"
            type="text/javascript">
    </script>

    <script src="[% prototype_js_file_eq %]"
            type="text/javascript">
    </script>

    <script type="text/javascript">
        var varStore = {
            centerLat      :'[% center_latitude %]',
            centerLng      :'[% center_longitude %]',
            centerZoom     :[% center_zoom %],
            imageHeightPix :'[% image_height_pix %]',
            tileHeightPix  :'[% tile_height_pix %]',
            imageWidthPix  :'[% image_width_pix %]',
            tileWidthPix   :'[% tile_width_pix %]',
            queryParams    :[[% param_fields %]], // This must be an array
            urlTemplate    :'[% url_template %]',
            clusterField   :'[% cluster_field %]',
            drawGrid       :'[% draw_grid %]'
        };
    </script>

    <!-- Execute scripts here (2/2) -->
    <script src="[% gmap_main_js_file_eq %]"
            type="text/javascript">
    </script>

    [% footer %]
</body>
</html>

CONTENT
    
    $files{'gmap-main.js'}{'type'}    = 'ascii';
    $files{'gmap-main.js'}{'content'} = <<'CONTENT';
// Author: Payan Canaran (pcanaran@cpan.org)
// Copyright 2006-2007 Cold Spring Harbor Laboratory
// $Id: Files.pm,v 1.13 2007/09/19 01:49:12 canaran Exp $

// Create and initialize map
var map = new GMap2(document.getElementById('map'));

var centerLat  = varStore.centerLat;
var centerLng  = varStore.centerLng;
var centerZoom = varStore.centerZoom;

// map.addControl(new GSmallZoomControl());
map.addControl(new GLargeMapControl());
map.addControl(new GMapTypeControl());
map.addControl(new GScaleControl());
map.setCenter(new GLatLng(centerLat, centerLng), centerZoom);

// Register map events
GEvent.addListener(map, "movestart", startRefresh);
GEvent.addListener(map, "zoomend",   limitZoom);
GEvent.addListener(map, "moveend",   limitVerticalMove);
GEvent.addListener(map, "moveend",   doRefresh);

// Register non-map events
var clusterField = varStore.clusterField;
if (clusterField && clusterField != '_default') {
    Event.observe(document.getElementById(clusterField), 'change', toggleClusterSlicesGroup);
}
Event.observe(window, 'load', doRefresh);

// [End of main script]

// Create a URL from form variables
function constructUrl() {
    var queryParams = varStore.queryParams;
    var urlTemplate = varStore.urlTemplate;

    // Determine geographic boundaries of the map in view
    var mapBounds = map.getBounds();

    var  boundSouthWest = mapBounds.getSouthWest();
    var  boundNorthEast = mapBounds.getNorthEast();

    var latNorth = boundNorthEast.lat();
    var lngEast  = boundNorthEast.lng();
    var latSouth = boundSouthWest.lat();
    var lngWest  = boundSouthWest.lng();

    // Make a copy of urlTemplate, will be overwritten
    var url = urlTemplate;

   // Retrieve and substitute query param values
   for (var i = 0; i < queryParams.length; i++) {
       var paramName = queryParams[i];
       var paramValue = document.getElementById(paramName).value;
       url += ';' + escape(paramName) + "=" + escape(paramValue);
   }

    // Add coordinates
    url += "&latitude_north=" + escape(latNorth);
    url += "&longitude_east=" + escape(lngEast);
    url += "&latitude_south=" + escape(latSouth);
    url += "&longitude_west=" + escape(lngWest);

    // Add clustering (slices) params
    if (document.getElementById('cluster_slices_group') 
        && Element.hasClassName(document.getElementById('cluster_slices_group'), 'visible')
        && document.getElementById('cluster_slices') 
        ) {
        url += "&cluster_slices="       + escape(document.getElementById('cluster_slices').checked);
        url += "&cluster_slices_value=" + escape(document.getElementById('cluster_slices_value').value);
        url += "&cluster_slices_by="    + escape(document.getElementById('cluster_slices_by').value);
    };

    //Add zoom level
    url += "&zoom_level=" + map.getZoom()
    
    // document.getElementById("debug").innerHTML = url;

    return url;
}

// Add latitude-longitude grid to map
function addLatLngLines() {
    var imageHeightPix = varStore.imageHeightPix;
    var tileHeightPix = varStore.tileHeightPix;

    var imageWidthPix  = varStore.imageWidthPix;
    var tileWidthPix  = varStore.tileWidthPix;

    var numberOfVerticalTiles   = imageHeightPix / tileHeightPix;
    var numberOfHorizontalTiles = imageWidthPix / tileWidthPix;

    // Determine geographic boundaries of the map in view
    var mapBounds = map.getBounds();

    var  boundSouthWest = mapBounds.getSouthWest();
    var  boundNorthEast = mapBounds.getNorthEast();

    var latNorth = boundNorthEast.lat();
    var lngEast  = boundNorthEast.lng();
    var latSouth = boundSouthWest.lat();
    var lngWest  = boundSouthWest.lng();

    var lngMid   = (lngWest < lngEast) ? lngWest + (lngEast - lngWest) / 2
                                       : lngWest + ((lngEast - (-180)) + (180 - lngWest)) / 2;
    if (lngMid > 180) { // Longitude +180 continues with -180
        lngMid = -180 + (lngMid - 180); // (lngMid - 180) is overflow over 180'
    }

    // Longitude +180 continues with -180
    tileSideLng = (lngWest < lngEast) ? (lngEast - lngWest) / numberOfHorizontalTiles              
                                      : ((lngEast - (-180)) + (180 - lngWest)) / numberOfHorizontalTiles;

    tileSideLat = (latNorth - latSouth) / numberOfVerticalTiles;

//  document.getElementById("debug").innerHTML =   '> latNorth:' + latNorth
//                                               + ' latSouth:' + latSouth
//                                               + '<br>'
//                                               + ' lngWest:'  + lngWest
//                                               + ' lngEast:'  + lngEast
//                                               + ' tileSideLng:'  + tileSideLng
//                                               + '<br/>';

    for (var n = 1; n < numberOfHorizontalTiles; n++) {
        // Draw longitudes
        var lngNth = lngWest + n * tileSideLng;

        if (lngNth > 180) { // Longitude +180 continues with -180
            lngNth = -180 + (lngNth - 180); // (lngNth - 180) is overflow over 180'
        }

        var polyline = new GPolyline([
            new GLatLng(latNorth, lngNth),
            new GLatLng(latSouth, lngNth)
            ], "#ff8b04", 2);
        map.addOverlay(polyline);
        map.addOverlay(polyline); // Every other polyline is skipped, a potential bug; observe 8/10/07        
    }   

    for (var n = 1; n < numberOfVerticalTiles; n++) {
        // Draw latitudes
        var latNth = latSouth + n * tileSideLat;

        var polyline = new GPolyline([
            new GLatLng(latNth, lngWest),
            new GLatLng(latNth, lngMid),   // A mid point is needed to ensure direction of the line is correct
            new GLatLng(latNth, lngEast)
            ], "#ff8b04", 2);
        map.addOverlay(polyline);
        map.addOverlay(polyline); // Every other polyline is skipped, a potential bug; observe 8/10/07       
    }

// document.getElementById("debug").innerHTML = 'zoom:' + map.getZoom();

    return 1;
}

// Start refresh (clear overlays and messages)
function startRefresh() {
    // Clear existing overlays
    map.clearOverlays();

    document.getElementById("status").innerHTML         = 'Moving ...';
    document.getElementById("legend").innerHTML         = '';
    document.getElementById("legend_message").innerHTML = '';
    document.getElementById("details").innerHTML        = '';
}

// Refresh display (clear overlays, send an AJAX request, process request)
function doRefresh(event) {
    var drawGrid = varStore.drawGrid;

    // Clear existing overlays
    map.clearOverlays();

    document.getElementById("status").innerHTML = "Refreshing ...";

    // Construct URL based on coordinates and form values
    var requestUrl = constructUrl();

    // Query database, pass results on for parsing
    GDownloadUrl(requestUrl, processRequest); // No parentheses

    // Draw grid
    if (drawGrid > 0) {
        addLatLngLines();
    }    
}

// Place markers on the map
function processRequest(data, responseCode) {
    var xml = GXml.parse(data);

    var markers = xml.documentElement.getElementsByTagName("marker");

    for (var i = 0; i < markers.length; i++) {
        var lat = parseFloat(markers[i].getAttribute("latitude"));
        var lng = parseFloat(markers[i].getAttribute("longitude"));

        var iconUrl         = markers[i].getAttribute("icon_url");
        var iconSize        = markers[i].getAttribute("icon_size");
        var messagesOnClick = markers[i].getAttribute("messages_on_click");
        var detailsOnClick  = markers[i].getAttribute("details_on_click");
        var legendOnClick   = markers[i].getAttribute("legend_on_click");

        var point = new GLatLng(lat, lng);

        addMarker(point, iconUrl, iconSize, legendOnClick, detailsOnClick, messagesOnClick);

        document.getElementById("details").innerHTML = '[Click on an icon on the map for details ...]';
    }

    var metaData = xml.documentElement.getElementsByTagName("meta_data"); // Only one present

    var legendByDefault   = metaData[0].getAttribute("legend_by_default");
    var detailsByDefault  = metaData[0].getAttribute("details_by_default")
    var messagesByDefault = metaData[0].getAttribute("messages_by_default")

    if (legendByDefault) {
        document.getElementById("legend").innerHTML = legendByDefault;
    }

    if (detailsByDefault) {
        document.getElementById("details").innerHTML = detailsByDefault;
    }

    if (messagesByDefault) {
        document.getElementById("messages").innerHTML = messagesByDefault;
    }

document.getElementById("status").innerHTML = "Ready";
}

// Utility function to add a marker
function addMarker(point, iconUrl, iconSize, legendOnClick, detailsOnClick, messagesOnClick) {
    var icon   = createIcon(iconUrl, iconSize);
    var marker = new GMarker(point, icon);

    if (legendOnClick) {
        GEvent.addListener(marker, "click", function() {
            document.getElementById("legend").innerHTML = legendOnClick;
        })
    };

    if (detailsOnClick) {
        GEvent.addListener(marker, "click", function() {
            document.getElementById("details").innerHTML = detailsOnClick;
        })
    };

    if (messagesOnClick) {
        GEvent.addListener(marker, "click", function() {
            document.getElementById("message").innerHTML = messagesOnClick;
        })
    };

    map.addOverlay(marker);
}

// Utility function to create an icon object to be used as a marker
function createIcon(imageUrl, size) {
    var icon                = new GIcon();
    icon.image              = imageUrl;

    icon.shadow             = "";
    icon.iconSize           = new GSize(size, size);
    icon.shadowSize         = "";
    icon.iconAnchor         = new GPoint(Math.floor(size/2)+1, Math.floor(size/2)+1);
    icon.infoWindowAnchor   = new GPoint(Math.floor(size/2)+1, Math.floor(size/2)+1);;
    return icon;
}

// Utility function to toggle cluster slices group
function toggleClusterSlicesGroup(event) {
    var element      = Event.element(event);
    var elementValue = element.value;

    var clusterSlicesGroup = document.getElementById("cluster_slices_group");

    if (elementValue == 'all') {
        clusterSlicesGroup.className = 'visible';
    }

    else {
        clusterSlicesGroup.className = 'hidden';
    }
}

// Utility function to limit zoom
function limitZoom() {
    var zoom = map.getZoom();

    if (zoom < 2) {
        map.setZoom(2);
    }
}

// Utility function to limit vertical move
function limitVerticalMove() {
    var mapBounds = map.getBounds();

    var  boundSouthWest = mapBounds.getSouthWest();
    var  boundNorthEast = mapBounds.getNorthEast();

    var latNorth = boundNorthEast.lat();
    var lngEast  = boundNorthEast.lng();
    var latSouth = boundSouthWest.lat();
    var lngWest  = boundSouthWest.lng();

    var latDelta = latNorth - latSouth;

    var mapCenter    = map.getCenter();
    var mapCenterLng = mapCenter.lng();

    if (latNorth > 84.5) {
        var newMapCenterLat = 84.5 - latDelta / 2;
        map.panTo(new GLatLng(newMapCenterLat, mapCenterLng));
    }    

    if (latSouth < -84.5) {
        var newMapCenterLat = -84.5 + latDelta / 2;
        map.panTo(new GLatLng(newMapCenterLat, mapCenterLng));
    }    
}

// End of Functions

CONTENT
    

    return \%files;
}

1;

__END__

=head1 NAME

HTML::GMap::Files - File storage for HTML::GMap

=head1 SYNOPSIS

  HTML::GMap::Files->new(temp_dir => '/tmp');

=head1 DESCRIPTION

This file is used by HTML::GMap as a storage for 
HTML template, CSS and Javascript files.

=head1 USAGE

This file is not intended to be used directly. Please refer to
HTML::GMap::Tutorial for detailed usage information.

=head1 AUTHOR

Payan Canaran <pcanaran@cpan.org>

=head1 BUGS

=head1 VERSION

Version 0.06

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2006-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut
