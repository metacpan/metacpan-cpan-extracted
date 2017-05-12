// global event handlers (loading and unloading the map and summaries)
// (it's here and not in the <body> tag in order to be able
//  to display 'Loading...' message)
var oldOnload = window.onload;
if (typeof window.onload != 'function') {
   window.onload = function() {
      summary_load();
      gmaps_load();
   };
} else {
   window.onload = function() {
      oldOnload();
      summary_load();
      gmaps_load();
   };
}
var oldOnunload = window.onunload;
if (typeof window.onunload != 'function') {
   window.onunload = function() {
      GUnload();
      summary_unload();
   };
} else {
   window.onunload = function() {
      oldOnunload();
      GUnload();
      summary_unload();
   };
}
