package Kwiki::JSLog;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_title => 'JSLog Library';
const class_id => 'jslog';

1; # End of Kwiki::JSLog
__DATA__
=head1 NAME

Kwiki::JSLog - Provides JSLog library for Kwiki

=head1 SYNOPSIS

This module should be optional and only really needed for developers of your
module. For this reason it does not load itself and therefore it is not
automatically included in the list of javascript files. Your module must
dynamically load the javascript file this module provides if it is needed.
The Kwiki-TableOfContents module provides a great example code for doing this.
The example code requires the prototype library and the scriptaculous library
but code could easy be created that does not depend on these libraries. Below
is the example code:

        debug = Prototype.emptyFunction;
        jslog = new Object();
        $A(['debug', 'info', 'warning', 'error', 'text']).each(function(func) {
                jslog[func] = Prototype.emptyFunction;
        });
        if (location.href.match(/jslog\=enable/)) {
                Scriptaculous.require('javascript/jslog.js');
        }

As you can see jslog.js is not included unless jslog=enable is in the URL
requested. Since a normal use will never request a URL with that in it then
the library will never be used. But to enable the log simply install this module
in the Kwiki installation and add that to your URLs. Empty functions are used
when this library is not included allowing you to leave your logging code in
the production modules.

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 ACKNOWLEDGEMENTS

Andre Lewis for developing the JSLog library. Without it debugging in
Javascript would have been much harder while working in IE.

=head1 COPYRIGHT & LICENSE

Copyright 2006 CorData, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See http://www.perl.com/perl/misc/Artistic.html

=cut
__javascript/jslog.js__
/*
Copyright (c) 2005, Andre Lewis, andre@earthcode.com
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided
that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of "Andre Lewis" nor the names of contributors to this software may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
jslog.js

Tokens placed in global namespace:
	EC -- a container for all things EarthCode. EF.F contains utility functions used across multible Earthcode projects.
	jslog -- the logger itself, with debug(), info(), warning(), error(), and text() methods
	debug -- a convenience method placed in the root to save you a few keystrokes for the often-used debug method.

Example Use:
jslog.info("Information here!");
debug("Here's some debug info"); // this is shorthand

To Utilize, include just one file:
	<script language="JavaScript" src="/scripts/jslog.js"></script>

To Utilize drag-and-drop, include these before including jslog.js:
	<script language="JavaScript" src="/scripts/lib/prototype.js"></script>
	<script language="JavaScript" src="/scripts/lib/scriptaculous/scriptaculous.js"></script>

More information at http://www.earthcode.com/tools/jslog

Created by Andre Lewis 12/05
*/

if (EC == null || typeof(EC) != "object") { var EC = new Object();}
if (EC.F == null || typeof(EC.F) != "object") { EC.F = new Object();}

/*
NOTE: here we are defining several functions which ALSO exist in the foundation library. They are defined here
so the debugging file can be completely self-contained.
*/
if (EC.F["setCookie"] == null) {
	/*
	 Method to set a cookie.
	*/
	EC.F.setCookie = function (name, value) {
		var cookietext = name + "=" + escape(value);
		document.cookie = cookietext;
		return null;
	} // end of setCookie function

	/*
	 Method to get a cookie.
	*/
	EC.F.getCookie = function (Name) {
		var search = Name + "=";
		var CookieString = document.cookie;
		var result = null;
		if (CookieString.length > 0) {
			offset = CookieString.indexOf(search);
			if (offset != -1) {
				offset += search.length;
				end = CookieString.indexOf(";", offset);
				if (end == -1){
					end = CookieString.length;
				}
				result = unescape(CookieString.substring(offset, end));
			}
		}
		return result
	} // end of getCookie function
}

var jslog = new function () {
	bPersistState = true;
	/*------------------------------------------------------------------------------------
	 Namespacing
	 ------------------------------------------------------------------------------------*/
	var sNamespace="ec_debug_logging";
	var sInstance="jslog";
	var sDOMInstance=sNamespace+"_"+sInstance;


	// *** START Configuration ***
	var Config_Enabled = true;
	// *** END Configuration ***

	if(Config_Enabled == false && location.href.match(/enablejslog/)) {
		Config_Enabled = true;
	}

	var bLoggerConfigured=false;
	var nNumMsgsLogged = 0;

	// Helpers
	function $(o){return document.getElementById(o)};

	/*------------------------------------------------------------------------------------
	 Public Methods
	 ------------------------------------------------------------------------------------*/

	function debug(msg) {
		logMsg("DEBUG",msg);
	}
	function info(msg) {
		logMsg("INFO",msg);
	}
	function warning(msg) {
		logMsg("WARN",msg);
	}
	function error(msg) {
		logMsg("ERROR",msg);
	}

	// This method toggles the on-screen display div on or off as needed
	function toggleDisplay() {
		var oBody = $(sDOMInstance+'_body');
		if (oBody.style.display == 'none') {
			oBody.style.display = 'block';
		} else {
			oBody.style.display = 'none';
		}

		if (bPersistState) {
			EC.F.setCookie(sInstance+"_visibility",oBody.style.display);
		}

	}

	// this function clears the on-screen display
	function clearLog() {
		$(sDOMInstance+'_logDisplay').innerHTML = '';
		nNumMsgsLogged = 0;
		$(sDOMInstance+'_handle').innerHTML=nNumMsgsLogged;
	}

	/*
	Public method to programmatically enable jslog, even if it's turned off via the config.
	Use this if you want jslog generally turned off, but turned on for one specific page.

	If the logger is already enabled, does nothing.
	*/
	function enable() {
		if (!bLoggerConfigured) {
			initializeDisplay();
		}
	}

	/*
	Public method to set any amount of text into the text area
	*/
	function text(sText) {
		$(sDOMInstance+"_textArea").value=sText;
	}
	/*
	Public method to try to get the innerHTML of the element identified in the text input box, and place it into the clipboard
	from view.
	*/
	function getHTML () {
		var sIdToInspect = $(sDOMInstance+"_idToInspect").value;

		if (sIdToInspect == "" ) {
			warning("Provide a non-blank id");
		} else {
			try {
				// get the element with the id entered, copy its outerHTML to a hidden text area, and then transfer it to the clipboard
				var oTextArea = $(sDOMInstance+"_textArea").value = $(sIdToInspect).innerHTML;
				info(sIdToInspect+" innerHTML is now in the text box below!");
			} catch(e) {
				error("Could not get innerHTML of id="+sIdToInspect+": "+e.message);
			}
			// finally, persist the id that was entered in a cookie
			EC.F.setCookie(sInstance+"_idToInspect",sIdToInspect);
		}
	}


	// Specify the methods that are to be public here. This is what exposes them publicly
	this.debug=debug;
	this.info=info;
	this.warning=warning;
	this.error=error;
	this.toggleDisplay=toggleDisplay;
	this.clearLog=clearLog;
	this.text=text;
	this.enable = enable;
	this.getHTML = getHTML

	/*------------------------------------------------------------------------------------
	 Private Methods
	 ------------------------------------------------------------------------------------*/

	//This function logs a message. All the level-specific methods (logger.debug, etc.) turn around and call this methods
	function logMsg(level,msg) {
		if (Config_Enabled) {
			// increase the count in the handle
			nNumMsgsLogged +=1;
			$(sDOMInstance+'_handle').innerHTML=nNumMsgsLogged;
			// Append the log to a display div so it can be seen right away
			var oDisplay =$(sDOMInstance+'_logDisplay');
			if (oDisplay.childNodes.length == 0 ) {
				oDisplay.appendChild(createDisplayRow(level,msg));
			} else {
				oDisplay.insertBefore(createDisplayRow(level,msg),oDisplay.childNodes[0]);
			}
	} // end of is config enabled
	}

	// this private method creates the row to add the the display div. It generates what actually gets shown
	// in the appropriate div each time there's a logged event
	function createDisplayRow(sLevel, sMsg) {
		if (document.all) { // very basic browser detection
			var sFloat="styleFloat"; //ie
		} else {
			var sFloat="cssFloat"; //firefox
		}
		var oRes = document.createElement("div");
		if (nNumMsgsLogged/2 == Math.floor(nNumMsgsLogged/2)) {
			oRes.style.backgroundColor="#FFF";
		} else {
			oRes.style.backgroundColor="#F6F6F6";
		}
		oRes.style.borderBottom="1px solid #AAA";
		oRes.style.verticalAlign="top";
		var oSev=document.createElement("div");
		oSev.style.width="40px";
		oSev.style.paddingLeft="3px";
		oSev.style[sFloat]="left";

		// different styles for different severities
		if (sLevel == "DEBUG") {
			oSev.style.backgroundColor="#1515FF";
		} else if (sLevel == "INFO") {
			oSev.style.backgroundColor="#10FF10";
		} else if (sLevel == "WARN") {
			oSev.style.backgroundColor="yellow";
		} else if (sLevel == "ERROR") {
			oSev.style.backgroundColor="#FF7070";
		}

		oSev.appendChild(document.createTextNode(sLevel));
		oRes.appendChild(oSev);
		var oTime= document.createElement("span");
		oTime.style.paddingLeft="3px";
		oTime.style.paddingRight="8px";
		oSev.style[sFloat]="left";
		oTime.appendChild(document.createTextNode(getCurrentTimeFormatted()));
		oRes.appendChild(oTime);

		oRes.appendChild(document.createTextNode(sMsg));

		var oClear=document.createElement("div");
		oClear.style.clear="both";
		oRes.appendChild(oClear);

		return oRes;
	}

	// this private method returns the current date formated properly with a nice AM/PM
	function getCurrentTimeFormatted() {
		var now = new Date();
		var hours = now.getHours();
		var minutes = now.getMinutes();
		var seconds = now.getSeconds()
		var timeValue = "" + ((hours >12) ? hours -12 :hours);
		if (timeValue == "0") timeValue = 12;
		timeValue += ((minutes < 10) ? ":0" : ":") + minutes;
		timeValue += ((seconds < 10) ? ":0" : ":") + seconds;
		timeValue += (hours >= 12) ? " PM" : " AM";

		return timeValue;
	}

	if (Config_Enabled) {
		initializeDisplay();
	}

	/*------------------------------------------------------------------------------------
	 Initialization code. It's wrapped in a try-catch block because if something here
	 fails, there is no other notification
	 ------------------------------------------------------------------------------------*/
	function initializeDisplay() {
		if (!bLoggerConfigured) {
			// Create the display div if necessary. This writes directly to the document to create the UI for the logger.
			// Note also that there are onclick events here, which call back to the public methods of the class.
			try {

				// default positions if other positions are not available
				var nTop=2;
				var nLeft=2;
				var sDisplay="none";

				if (bPersistState) {
					try {
						var sPersistString = EC.F.getCookie(sInstance+"_position");
						if (sPersistString != null) {
							var aTemp = sPersistString.split("|");
							if(!isNaN(parseInt(aTemp[0]))) {
								nLeft = aTemp[0];
							}
							if(!isNaN(parseInt(aTemp[1]))) {
								nTop = aTemp[1];
							}

						}

						if(EC.F.getCookie(sInstance+"_visibility") == "block") {
							sDisplay="block";
						}
					} 	catch (e) {
						// nullop, just leave the arguments as the default
					}
				} // end if bPersistState

				var sIdToInspect = EC.F.getCookie(sInstance+"_idToInspect");
				sIdToInspect = sIdToInspect==null?"":sIdToInspect;

				document.write('<div id="'+sDOMInstance+'_container" style="font-family:arial; color:black; font-size:9px; line-height:normal; letter-spacing: normal; position:absolute; z-index:10000;top:'+nTop+'px; left:'+nLeft+'px; ">'+
								 '<div id="'+sDOMInstance+'_handle" style="cursor:move; position: absolute; background-color:#FFFFCC; border:1px solid #FF0400; color:black; padding:2px;" ondblclick="'+sInstance+'.toggleDisplay()">0</div>'+
								 '<div id="'+sDOMInstance+'_body" style="text-align:left; border:1px solid #FF0400; width:300px; position: absolute; top:20px; left:0px; background-color:white; display:'+sDisplay+'">'+
								 '<div id="'+sDOMInstance+'_header" style="height:10px; padding:2px; border-bottom:1px solid black; background-color:#FFFFCC;">'+
								 '<span id="'+sDOMInstance+'_clear" style="color: blue;" onclick="'+sInstance+'.clearLog()">clear</span>'+
								 '</div>'+
								 '<div id="'+sDOMInstance+'_logDisplay" style="height:240px; overflow:auto;"></div>'+
								 '<div id="'+sDOMInstance+'_footer" style="padding-left:2px; border-top:1px solid black; background-color:#FFFFCC;">'+
								 'get html:<input id="'+sDOMInstance+'_idToInspect" style="font-size:9px; height:18px;" value="'+sIdToInspect+'" size=42/> <span id="'+sDOMInstance+'_go" style="color: blue;" onclick="'+sInstance+'.getHTML()">go</span>'+
								 '<textarea id="'+sDOMInstance+'_textArea" style="width:99%; font-size:9px;"></textarea>'+
								 '</div></div></div></div>');

				// Allow browser to construct DOM elements
				setTimeout(function() {
				$(sDOMInstance+"_clear").style.cursor="pointer";
				$(sDOMInstance+"_go").style.cursor="pointer";

				// Check if the draggable library is provided. This would be true if the appropriate libraries
				// are included in the page via a <script> tag
				if (window['Draggable'] != null) {
					// draggable is available, so use it!
					new Draggable(sDOMInstance+'_container',{handle:sDOMInstance+'_handle', revert:false,
						starteffect:false, endeffect:false});

					// if the persistState option is true, set up the listener as appropriate
					if (bPersistState) {
						var fMyDropListener = new function() {
							this.onStart = function(){};
							this.onEnd = function(s,o) {
								if (o.element.id == sDOMInstance+"_container"){
									var pos = Position.cumulativeOffset(o.element);
									EC.F.setCookie(sInstance+"_position",+pos[0]+"|"+pos[1]);
								}
							}
						}

						Draggables.addObserver(fMyDropListener);
					}
				} else {
					// Otherwise, it means sciptaculous is not included, and debug won't be draggable
					// change the cursor on the loggerHandle
					$(sDOMInstance+'_handle').style.cursor="pointer";
				}
				}, 100);

				bLoggerConfigured=true;
			} catch (e) {
				alert("Code-level error initializing jslog: "+e.description);
			}
		} // end of initializeDisplay
	}
}
debug=jslog.debug;
