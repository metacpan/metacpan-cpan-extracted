// directory with data
var DATA_DIR = "data";

// filename with markers of places of interest
var POI_URL = "pois.xml";

var map;

// overview (a small map in the corner of a big map) globals
var overviewShow = 1;
var overviewHeight = 150;
var overviewWidth = 150;
var overviewHeight = 150;
var overviewWidth = 150;

// starting location and zoom level
var LOC_SVALBARD = new GLatLng (78.216666, 15.55);  // Longyearbyen
var ZOOM_SVALBARD = 8;
var DENSITY_ALL = "all";

// custom icons
var ICON_MAIN_IDX = 0; // index of main expedition icon
var ICON_DAY_IDX  = 1; // index of the "one-per-day" expedition icon
var ICON_SUPL_IDX = 2; // index of supplementary expedition icon (like for depots)
var ICON_POI_IDX  = 3; // index of places of interest icon

var baseIcon = new GIcon();
baseIcon.shadow = "icons/flag-shadow.png";
baseIcon.iconSize = new GSize(25, 25);
baseIcon.shadowSize = new GSize(53, 34);
baseIcon.iconAnchor = new GPoint(6, 20);
baseIcon.infoWindowAnchor = new GPoint(5, 1);

var icons = [];
icons[ICON_MAIN_IDX] = new GIcon (baseIcon);
icons[ICON_MAIN_IDX].image = "icons/tiny_red.png";
icons[ICON_MAIN_IDX].shadow = "icons/tiny_shadow.png";
icons[ICON_MAIN_IDX].iconSize = new GSize(12, 20);
icons[ICON_MAIN_IDX].shadowSize = new GSize(22, 20);

icons[ICON_DAY_IDX] = new GIcon (baseIcon);
icons[ICON_DAY_IDX].image = "icons/flag-orange.png";

icons[ICON_SUPL_IDX] = new GIcon (baseIcon);
icons[ICON_SUPL_IDX].image = "icons/flag-blue.png";

icons[ICON_POI_IDX] = new GIcon (baseIcon);
icons[ICON_POI_IDX].image = "icons/flag-yellow.png";

// -----------------------------------------
// this function is called when a page loads
// -----------------------------------------
function gmaps_load() {
   if (GBrowserIsCompatible()) {

      initMap();
      loadMarkers ("output-" + getRouteDensity() + ".xml");
      loadPlacesOfInterest (POI_URL);

   } else {
      var msg = "Sorry, the Google Maps API is not compatible with this browser. Or another problem occurred.";
      var mapDiv = document.getElementById ("map");
      mapDiv.innerHTML = msg;
   }
}

function initMap() {
   map = new GMap2 (document.getElementById ("map"));
   map.addControl(new GLargeMapControl());
   map.addControl(new GMapTypeControl());
   map.addControl(new GScaleControl());

   // set initial map center and zoom level
   map.setCenter (LOC_SVALBARD, ZOOM_SVALBARD);

   // enable an overview map (in the corner of a real map)
   map.addControl (new GOverviewMapControl (new GSize (overviewWidth, overviewHeight)));
}

// ---------------------------------------------
// Redraw the map when a new density is selected
// ---------------------------------------------
function changeMap() {
   map.clearOverlays();
   loadMarkers ("output-" + getRouteDensity() + ".xml");
   loadPlacesOfInterest (POI_URL);
}

// ---------------------------------------------------------------
// Select how many markers toi display. It returns a base filename
// with markers of such density.
// ---------------------------------------------------------------
function getRouteDensity() {
   var density = document.getElementById ("density");
   if (density != null) {
      var idxSelectedDensity = density.selectedIndex;
      if (idxSelectedDensity < 0)
	 idxSelectedDensity = 0;
      return (density.options [idxSelectedDensity].value);
   } else {
      return ("oneperday");
   }
}

// -------------------------------------------------------------
// a wrapper around GDownloadUrl(), adding some request headers;
//    url  ... what to download (add the prefix DATA_DIR first)
//    func ... a function called to process the results
//             func (receivedData, receivedResposeStatus)
// -------------------------------------------------------------
function download (url, func) {

   showLoading ("Loading...");
   var request = GXmlHttp.create();
   request.open ("GET", DATA_DIR + "/" + url + "?ran=" + Math.random(), true);  // hack removing caching
// The below - what is commented-out - did not work;
// that's why I am using Math.random (above) to make URLs always
// different to avoid caching.
//
//   request.overrideMimeType ("text/xml");
//   request.setRequestHeader ('Cache-Control', 'no-cache');
   request.onreadystatechange = function() {
      if (request.readyState == 4) {
	 showLoading ("&nbsp;");
	 func (request.responseText, request.status);
      }
   }
   request.send (null);
}

function showLoading (text) {
   var div = document.getElementById ("progressDisplay");
   if (div != null) {
      div.innerHTML = text;
   }
}


function loadMarkers (url) {

   // Download the data from given 'url' and load it on the map.
   // The format we expect is:
   // <markers>
   //   <marker lat="78.22262" lng="15.65234" time="2006-08-23 01:44:08" type="1"/>
   //   <marker lat="78.22258" lng="15.65228" time="2006-08-22 17:41:27" type="0"/>
   // </markers>
   return download (url, function (data, responseCode) {
      var countDiv = document.getElementById ("markerCount");
      var lastDiv = document.getElementById ("lastPoint");
      if (responseCode != 200) {
         alert ("Sorry, the map request failed: " + responseCode);
	 countDiv.innerHTML = "unknown";
	 lastDiv.innerHTML = "unknown";
         return;
      }
      var points = [];
      var xml = GXml.parse (data);
      var markers = xml.documentElement.getElementsByTagName ("marker");

      countDiv.innerHTML = markers.length;
      if (markers.length > 0) {
	 var time = markers [markers.length - 1].getAttribute ("time");
	 lastDiv.innerHTML = time.replace (" ", "&nbsp;");
      }

      var lastOne;
      for (var i = 0; i < markers.length; i++) {
	 var point = new GLatLng (parseFloat (markers[i].getAttribute ("lat")),
				  parseFloat (markers[i].getAttribute ("lng")));
	 points.push (point);
	 var marker = createMarker (point, markers[i]);
	 map.addOverlay (marker);
	 lastOne = point;
      }
      // connect markers with a polyline
      var density = getRouteDensity();
      if (density != DENSITY_ALL)
	 map.addOverlay (new GPolyline (points));

      // move map center
      if (lastOne) {
	 map.setCenter (lastOne);
      }
   });
}


function createMarker (point, xmlMarker) {
   var type = xmlMarker.getAttribute ("type");
   var name = xmlMarker.getAttribute ("time");
   if (name == null)
      name = xmlMarker.getAttribute ("name");

   var desc;
   var element = xmlMarker.firstChild;
   if (element != null)
      desc = element.nodeValue;
   if (desc == null)
      desc = "";

   var marker = new GMarker (point, {icon: icons[type], title: name} );
   GEvent.addListener (marker, "click", function() {
      marker.openInfoWindowHtml ("<b><u>" + name + "</b></u><br>" + 
				 "<b>Lat:</b> " + point.lat() + "<br>" +
				 "<b>Lng:</b> " + point.lng() + "<p>" +
				 desc
				 );
   });
   return marker;
}


function loadPlacesOfInterest (url) {

   // Download the data from given 'url' and load it on the map.
   // The format we expect is:
   // <markers>
   //   <marker lat="78.22262" lng="15.65234" name="...">description</marker>
   //   ...
   // </markers>
   return download (url, function (data, responseCode) {
      if (responseCode != 200) {
         alert ("Sorry, the map request failed: " + responseCode);
         return;
      }
      var points = [];
      var xml = GXml.parse (data);
      var markers = xml.documentElement.getElementsByTagName ("marker");

      for (var i = 0; i < markers.length; i++) {
	 var point = new GLatLng (parseFloat (markers[i].getAttribute("lat")),
				  parseFloat (markers[i].getAttribute("lng")));
	 points.push (point);
	 var marker = createMarker (point, markers[i]);
	 map.addOverlay (marker);
      }
   });
}

