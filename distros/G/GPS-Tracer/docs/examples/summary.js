var SUMMARY_FILE = 'data/output-summary.xml';
var NA = '[no data available]';

function summary_load() {
   new Ajax.Request (SUMMARY_FILE + '?ran=' + Math.random(),
		     {
			method:'get',
			onSuccess: useSummary,
			onFailure: onFailure
		     });
}

function summary_unload() {
}

// ------------------
// Expedition summary
// ------------------

function onFailure() {

   var errDiv = document.getElementById ('errormsg');
   errDiv.style.display = 'block';
   errDiv.innerHTML =
   'Expedition data are not available, or they are corrupted. ' +
   'Please try again later, or contact author of this page. ' +
   'Thank you.';

}

function useSummary (transport) {
   var totals = transport.responseXML.getElementsByTagName ("total")[0];
   if (totals) {
      var kms = totals.getAttribute ('kms');
      if (kms && kms == parseFloat (kms)) {
	 kms = Math.round (kms * 10) / 10;
      } else {
	 kms = NA;
      }
      document.getElementById ('totalkms').innerHTML = kms;

   } else {
      document.getElementById ('totalkms').innerHTML = NA;
   }
}
