/*--------------------------------------------------------------------------
 * Software License Agreement (BSD License)
 * EdgeExpressDB [eeDB] system
 * copyright (c) 2007-2009 Jessica Severin RIKEN OSC
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *    * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *    * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *    * Neither the name of Jessica Severin RIKEN OSC nor the
 *     names of its contributors may be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *--------------------------------------------------------------------------*/


var ns4 = document.layers;
var ns6 = document.getElementById && !document.all;
var ie4 = document.all;
offsetX = 0;
offsetY = 20;
var toolTipSTYLE="";
var winW = 630, winH = 460;
var toolTipWidth = 300;

function initToolTips() {
  if(ns4||ns6||ie4) {
    if(ns4) toolTipSTYLE = document.toolTipLayer;
    else if(ns6) toolTipSTYLE = document.getElementById("toolTipLayer").style;
    else if(ie4) toolTipSTYLE = document.all.toolTipLayer.style;
    if(ns4) document.captureEvents(Event.MOUSEMOVE);
    else {
      toolTipSTYLE.visibility = "visible";
      toolTipSTYLE.display = "none";
    }
    document.onmousemove = moveToMouseLoc;
  }
  window.onresize = getNewWindowSize;
  getNewWindowSize();
}


function moveToMouseLoc(e) { 
  var posx = 0;
  var posy = 0;
  if(!e) var e = window.event;
  if(e.pageX || e.pageY) {
    posx = e.pageX;
    posy = e.pageY;
  }
  else if(e.clientX || e.clientY) {
    posx = e.clientX + document.body.scrollLeft
         + document.documentElement.scrollLeft;
    posy = e.clientY + document.body.scrollTop
         + document.documentElement.scrollTop;
  }

  var hscale = posx / winW; 
  if(hscale > 1.0) hscale=1.0;
  toolTipSTYLE.left = (posx - Math.floor((toolTipWidth+10)*hscale)) +'px'; 
  toolTipSTYLE.top = (posy + offsetY) +'px';
  toolTipSTYLE.xpos = posx;
  toolTipSTYLE.ypos = posy;
  return true;
}


function GetXmlHttpObject() {
  var xmlHttp=null;
  try { xmlHttp=new XMLHttpRequest(); }// Firefox, Opera 8.0+, Safari
  catch(e) {
    try { xmlHttp=new ActiveXObject("Msxml2.XMLHTTP"); } // Internet Explorer
    catch(e) { xmlHttp=new ActiveXObject("Microsoft.XMLHTTP"); }
  }
  return xmlHttp;
}


function getNewWindowSize() {
  if(parseInt(navigator.appVersion)>3) {
    if(navigator.appName.indexOf("Microsoft")!=-1) {
      winW = document.body.offsetWidth;
      winH = document.body.offsetHeight;
    } else { //should cover all other modern browsers
      winW = window.innerWidth;
      winH = window.innerHeight;
    }
  }

  // not sure how to get this dynamically
  winW -= 20; /* whatever you set your body bottom margin/padding to be */
  winH -= 20; /* whatever you set your body bottom margin/padding to be */
};


function allBrowserGetElementsByClassName(src, className) {
  if(ns4||ns6||ie4) {
    var hasClassName = new RegExp("(?:^|\\s)"+className+"(?:$|\\s)");

    var hasClassName = new RegExp("(?:^|\\s)"+className+"(?:$|\\s)");
    var allElements = src.getElementsByTagName("*");
    var results = [];
    var element;
    for(var i=0;(element=allElements[i])!=null;i++) {
      var elementClass=element.className;
      if(elementClass && elementClass.indexOf(className)!=-1 && hasClassName.test(elementClass)) {
        results.push(element);
      }
    }
    return results;
  } else {
   return src.getElementsByClassName(className);
  }
}


