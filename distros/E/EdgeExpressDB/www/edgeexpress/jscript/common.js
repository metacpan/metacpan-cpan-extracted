/*  EdgeExpressDB [eeDB] JavaScript toolkits, version 1.007
 *  common.js
 *  (c) 2007-2009 Jessica Severin RIKEN OSC
 *
 *  EdgeExpresDB is freely distributable under the terms of the perl
 *  artistic license 1.0
 *  For details, see http://www.perlfoundation.org/artistic_license_1_0
 *
 *--------------------------------------------------------------------------*/


var ns4 = document.layers;
var ns6 = document.getElementById && !document.all;
var ie4 = document.all;
offsetX = 0;
offsetY = 20;
var toolTipSTYLE="";
var winW = 630, winH = 460;
var toolTipWidth = 300;

function initToolTips()
{
  if(ns4||ns6||ie4)
  {
    if(ns4) toolTipSTYLE = document.toolTipLayer;
    else if(ns6) toolTipSTYLE = document.getElementById("toolTipLayer").style;
    else if(ie4) toolTipSTYLE = document.all.toolTipLayer.style;
    if(ns4) document.captureEvents(Event.MOUSEMOVE);
    else
    {
      toolTipSTYLE.visibility = "visible";
      toolTipSTYLE.display = "none";
    }
    document.onmousemove = moveToMouseLoc;
  }
  window.onresize = getNewWindowSize;
  getNewWindowSize();
}

function moveToMouseLoc(e)
{  var posx = 0;
        var posy = 0;
        if (!e) var e = window.event;
        if (e.pageX || e.pageY)         {
                posx = e.pageX;
                posy = e.pageY;
        }
        else if (e.clientX || e.clientY)        {
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

function GetXmlHttpObject()
{
        var xmlHttp=null;
        try
          {       xmlHttp=new XMLHttpRequest();         }// Firefox, Opera 8.0+, Safari
        catch (e)
          {
          try
                {       xmlHttp=new ActiveXObject("Msxml2.XMLHTTP");    } // Internet Explorer
          catch (e)
          {     xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");    }
         }
        return xmlHttp;
}


function getNewWindowSize() {

  if (parseInt(navigator.appVersion)>3) {
    if (navigator.appName.indexOf("Microsoft")!=-1) {
      winW = document.body.offsetWidth;
      winH = document.body.offsetHeight;
    }
    else { //should cover all other modern browsers
      winW = window.innerWidth;
      winH = window.innerHeight;
    }
  }

  // not sure how to get this dynamically
  winW -= 20; /* whatever you set your body bottom margin/padding to be */
  winH -= 20; /* whatever you set your body bottom margin/padding to be */
};

