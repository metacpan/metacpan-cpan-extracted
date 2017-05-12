/*
 * sIFR - jQuery plugin for accessible, unobtrusive flash image replacement.
 *
 * Based upon the work of Mike Davidson, Shaun Inman, Tomas Jogin and Mark
 * Wubben. Mike Davidson released his software under the CC-GNU LGPL
 * http://creativecommons.org/licenses/LGPL/2.1/
 *
 * Since this is my own rewrite of his implementation, (ONLY) this plugin
 * is licensed under thesame conditions as other plugins from jQuery.
 *
 * NOTE: Transparency is not supported in Opera 7.x, Safari < 1.2 & Flash 6,
 * in Linux, and in very old (pre 1.0) Mozilla versions. (NOT CHECKED FOR!!)
 *
 * I choose NOT to do so many checks on the passed parameters, since i think
 * we can assume people have the right browser if they are running jQuery.
 *
 * For more configuration options, see the original sifr documentation at the
 * website of Mike Davidson: http://www.mikeindustries.com/sifr/
 *
 * Copyright (c) 2006 Gilles van den Hoven (webunity.nl)
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * v0.1
 */

jQuery.sifr =	{
	blnFlashValid: null,
	/**
	 * Trys to retreive the Flash version from the visitor's browser
	 * @acces private
	 * @param integer major version
	 * @param integer minor version
	 * @param integer revision version
	 */
	_checkFlash: function(intMajor, intMinor, intRevision) {
		var arrFlash = null;
		var strFlash = '';

		// First check
		if (navigator.plugins && navigator.mimeTypes.length) {
			var objFlash = navigator.plugins["Shockwave Flash"];
			if (objFlash && objFlash.description)
				arrFlash = objFlash.description.replace(/([a-zA-Z]|\s)+/, "").replace(/(\s+r|\s+b[0-9]+)/, ".").split(".");
			objFlash = null;
		}

		// Second attempt
		if (!arrFlash) {
			try {
				var objFlash = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.7");
			} catch(errB) {
				try {
					arrFlash = [6, 0, 21];

					// Create object
					var objFlash = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.6");

					// Throws if player version < 6.0.47
					objFlash.AllowScriptAccess = "always";

					// If we came here, we can do a version lookup
					if (objFlash && objFlash.major)
						arrFlash = [objFlash.major, objFlash.minor, objFlash.revision];
					objFlash = null;
				} catch(errC) {
				}
			}

			// Third attempt (geez!)
			if (!arrFlash) {
				try {
					objFlash = new ActiveXObject("ShockwaveFlash.ShockwaveFlash");
					arrFlash = objFlash.GetVariable("$version").split(" ")[1].split(",");
					objFlash = null;
				} catch(errA) {
					arrFlash = [0, 0, 0];
				}
			}
		}

		//alert('<DEBUG> Your flash version is: ' + arrFlash[0] + '.' + arrFlash[1] + '.' + arrFlash[2]);

		// Set variable
		jQuery.sifr.blnFlashValid = ((arrFlash[0] >= intMajor) &&
																(arrFlash[1] >= intMinor) &&
																(arrFlash[2] >= intRevision));
	},
	/**
	 * Escape the input value
	 * @acces private
	 * @param string to convert
	 */
	_escapeHex: function(strInput){
		if(jQuery.browser.msie){ /* The RegExp for IE breaks old Gecko's, the RegExp for non-IE breaks IE 5.01 */
			return strInput.replace(new RegExp("%\d{0}", "g"), "%25");
		}
		return strInput.replace(new RegExp("%(?!\d)", "g"), "%25");
	},
	/**
	 * Retreives and rebuilds the contents of this node.
	 * @acces private
	 */
	_fetchContent: function(objNode, objNodeNew, strCase, intLinks, strLinkVars) {
		var strContent = "";
		var objSearch = objNode.firstChild;
		var objRemove, objNodeRemoved, objTemp, sValue;

		if (intLinks == null)
			intLinks = 0;

		if (strLinkVars == null)
			strLinkVars = "";

		while (objSearch) {
			if (objSearch.nodeType == 3) {
				sValue = objSearch.nodeValue.replace("<", "&lt;");
				switch(strCase) {
					case "lower":
						strContent+= sValue.toLowerCase();
						break;
					case "upper":
						strContent+= sValue.toUpperCase();
						break;
					default:
						strContent+= sValue;
				}
			} else if(objSearch.nodeType == 1) {
				if (jQuery.sifr._matchNodeName(objSearch, "a") && !objSearch.getAttribute("href") == false) {
					if (objSearch.getAttribute("target"))
						strLinkVars+= "&sifr_url_" + intLinks + "_target=" + objSearch.getAttribute("target");

					strLinkVars+= "&sifr_url_" + intLinks + "=" + jQuery.sifr._escapeHex(objSearch.getAttribute("href")).replace(/&/g, "%26");
					strContent+= '<a href="asfunction:_root.launchURL,' + intLinks + '">';
					intLinks++;
				} else if (jQuery.sifr._matchNodeName(objSearch, "br")) {
					strContent+= "<br/>";
				}

				// Fetch information about the childnodes
				if (objSearch.hasChildNodes()) {
					// The childNodes are already copied with this node, so objNodeNew = null
					objTemp = jQuery.sifr._fetchContent(objSearch, null, strCase, intLinks, strLinkVars);
					strContent+= objTemp.strContent;
					intLinks = objTemp.intLinks;
					strLinkVars = objTemp.strLinkVars;
					objTemp = null;
				}

				// Add the closing tag
				if (jQuery.sifr._matchNodeName(objSearch, "a")){
					strContent+= "</a>";
				}
			}
			objRemove = objSearch;
			objSearch = objSearch.nextSibling;

			if (objNodeNew != null){
				objNodeRemoved = objRemove.parentNode.removeChild(objRemove);
				objNodeNew.appendChild(objNodeRemoved);
			}
		}

		return { 'strContent': strContent, 'intLinks': intLinks, 'strLinkVars': strLinkVars };
	},
	/**
	 * Look if the matched node matches
	 * @acces private
	 * @param object to check
	 * @param string to match
	 */
	_matchNodeName: function(objNode, strMatch){
		return (strMatch == "*") ? true : (objNode.nodeName.toLowerCase().replace("html:", "") == strMatch.toLowerCase());
	},
	/**
	 * Helper function to support older browsers!
	 */
	_normalize: function(strInput) {
		return strInput.replace(/\s+/g, " ");
	},
	/**
	 * Main build function
	 * @acces public
	 * @param hash of options
	 */
	build: function(arrConfig) {
		var arrOptions = jQuery.extend({
			intRequiredFlashVersion: [6, 0, 0],
			strSWF: '',
			strColor: '#000000',
			strBgColor: '',
			strLinkColor: '',
			strHoverColor: '',
			intPadding: [0, 0, 0, 0],	// Left, top, right, bottom
			strFlashVars: '',
			strCase: '',
			strWmode: ''							// empty/'transparent'/'opaque'
		}, arrConfig || {});

		// Check config
		if (arrOptions.intPadding.length != 4) {
			alert('Wrong number of arguments for the padding!');
			return;
		}

		// helper to check for required flash version (do this only once per pageload)
		if (!jQuery.sifr.blnFlashValid) {
			jQuery.sifr._checkFlash(arrOptions.intRequiredFlashVersion[0], arrOptions.intRequiredFlashVersion[1], arrOptions.intRequiredFlashVersion[2]);
		}

		// Initialize flashvars
		if(arrOptions.strFlashVars != '')
			arrOptions.strFlashVars = jQuery.sifr._normalize(arrOptions.strFlashVars);

		// Remove & from the start
		if (arrOptions.strFlashVars.substr(0, 1) == '&')
			arrOptions.strFlashVars = arrOptions.strFlashVars.substr(1, arrOptions.strFlashVars.length);

		// Initialize colors
		if(arrOptions.strColor != '')
			arrOptions.strFlashVars+= "textcolor=" + arrOptions.strColor + '&';

		if (arrOptions.strHoverColor != null)
			arrOptions.strFlashVars+= 'hovercolor=' + arrOptions.strHoverColor + '&';

		if ((arrOptions.strLinkColor != null) || (arrOptions.strHoverColor != null))
			arrOptions.strFlashVars+= 'linkcolor=' + (arrOptions.strLinkColor || arrOptions.strColor) + '&';

	  // initialize sIFR
	  return this.each(function() {
	  	// Handle to object
	  	jqThis = jQuery(this);

	  	// Only continue if we support flash and haven't replaced allready
	  	if (jQuery.sifr.blnFlashValid && !jqThis.is('.sIFR-flash')) {
	  		// Calculate new width and height
	  		intWidth = parseInt(this.offsetWidth);
	  		intHeight = parseInt(this.offsetHeight);

	  		// If this fails, we don't have a width and height set, WHICH MUST BE THE CASE
	  		if (isNaN(intWidth) || isNaN(intHeight)) {
	  			alert('fook it');
	  			return;
	  		}

				// Remove padding
	  		intWidth-= (arrOptions.intPadding[0] +  arrOptions.intPadding[2]);
	  		intHeight-= (arrOptions.intPadding[1] +  arrOptions.intPadding[3]);

				// Make sure an & is at the end of the flashvars
				if (arrOptions.strFlashVars.substr(arrOptions.strFlashVars.length, 1) != '&')
					arrOptions.strFlashVars+= '&';

	  		// Build variables
				objAlternate = jQuery('<span class="sIFR-alternate"></span>')[0];
	  		objContent = jQuery.sifr._fetchContent(this, objAlternate, arrOptions.strCase);
				strVars = "txt=" + jQuery.sifr._normalize(jQuery.sifr._escapeHex(objContent.strContent).replace(/\+/g, "%2B").replace(/&/g, "%26").replace(/\"/g, "%22")) + '&';
				strVars+= arrOptions.strFlashVars;
				strVars+= "w=" + intWidth + "&h=" + intHeight + objContent.strLinkVars;
				objContent = null;

				// Generate!
				if (!jQuery.browser.msie) {
					strHTML = '<embed type="application/x-shockwave-flash" src="' + arrOptions.strSWF + '" quality="best" ';
					strHTML+= (arrOptions.strWmode != '') ? 'wmode="' + arrOptions.strWmode + '" ' : '';
					strHTML+= (arrOptions.strBgColor != '') ? 'bgcolor="' + arrOptions.strBgColor + '" ' : '';
					strHTML+= 'flashvars="' + strVars + '" width="' + intWidth + '" height="' + intHeight + '"></embed>';
				} else {
					strHTML = '<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="' + intWidth + '" height="' + intHeight + '">';
					strHTML+= '<param name="movie" value="' + arrOptions.strSWF + "?" + strVars + '"></param>';
					strHTML+= '<param name="quality" value="best"></param>';
					strHTML+= (arrOptions.strWmode != '') ? '<param name="wmode" value="' + arrOptions.strWmode + '"></param>' : '';
					strHTML+= (arrOptions.strBgColor != '') ? '<param name="bgcolor" value="' + arrOptions.strBgColor + '"></param>' : '';
					strHTML+= '</object>';
				}

				// Build the sifr tag
	  		jqThis.addClass('sIFR-flash').empty().append(objAlternate).append(strHTML);

	  		// Fix MSIE flash issue
	  		if (jQuery.browser.msie) {
	  			this.outerHTML = this.outerHTML;
	  		}
	  	}
	  });
	}
};

// Extend jQuery
jQuery.fn.extend( {
		sifr : jQuery.sifr.build
});
