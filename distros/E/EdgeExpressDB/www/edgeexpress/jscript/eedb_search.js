/*--------------------------------------------------------------------------
 * Software License Agreement (BSD License)
 * EdgeExpressDB [eeDB] system
 * copyright (c) 2007-2009 Jessica Severin RIKEN OSC
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Jessica Severin RIKEN OSC nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
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

var eedbRegistryURL;
var eedb_searchXHR_array = new Array();
var eedbSearchTracks = new Array();
var searchXMLHttp;
var eedbSearchServerURL = "../cgi/edgeexpress.fcgi";
var eedbPeerCache = new Object();

function eedbGetPeer(name) {
  if(!eedbRegistryURL) return;
  if(eedbPeerCache[name] != null) { return eedbPeerCache[name];}

  var url = eedbRegistryURL + "/cgi/edgeexpress.fcgi?peer=" + name;

  var peerXHR=GetXmlHttpObject();
  if(peerXHR==null) {
    alert ("Your browser does not support AJAX!");
    return;
  }
  peerXHR.open("GET",url,false);
  peerXHR.send(null);
  if(peerXHR.readyState!=4) return;
  if(peerXHR.responseXML == null) return;
  var xmlDoc=peerXHR.responseXML.documentElement;
  if(xmlDoc==null)  return;
  var peer = xmlDoc.getElementsByTagName("peer")[0];
  eedbPeerCache[name] = peer;
  return peer;
}

function eedbClearSearchResults(searchSetID) {
  var searchset = document.getElementById(searchSetID);
  if(!searchset) { return; }

  var searchDivs = allBrowserGetElementsByClassName(searchset,"EEDBsearch");
  for(i=0; i<searchDivs.length; i++) {
    var searchDiv = searchDivs[i];
    var peer = searchDiv.getAttribute("peer");
    if(peer) {
      searchDiv.innerHTML="<span style=\"font-weight:bold;color:Navy;\">"+ peer + "::</span> please enter search term";
    } else {
      searchDiv.innerHTML="please enter search term";
    }
    searchDiv.style.marginTop = "5px";
    searchDiv.style.marginBottom = "5px";
    searchDiv.style.color = 'black';
    searchDiv.style.size = '12';
    searchDiv.style.fontFamily = 'arial, helvetica, sans-serif';
    searchDiv.onmouseout = "eedbClearSearchTooltip();";
  }
  eedbClearSearchTooltip();
}

function eedbEmptySearchResults(searchSetID) {
  var searchset = document.getElementById(searchSetID);
  if(!searchset) { return; }
  var searchDivs = allBrowserGetElementsByClassName(searchset,"EEDBsearch");
  for(i=0; i<searchDivs.length; i++) {
    var searchDiv = searchDivs[i];
    searchDiv.innerHTML="";
  }
}


function eedbMultiSearch(searchSetID, str, e) {
  var searchset = document.getElementById(searchSetID);
  if(!searchset) { return; }
  var searchDivs = allBrowserGetElementsByClassName(searchset,"EEDBsearch");
  for(i=0; i<searchDivs.length; i++) {
    var searchDiv = searchDivs[i];
    eedbSearchSpecificDB(searchSetID, str, e, searchDiv);
  }
}


function eedbSearchSpecificDB(searchSetID, str, e, searchDiv) {
  var charCode;
  if(e && e.which) charCode=e.which;
  else if(e) charCode = e.keyCode;

  if (str.length<3 && charCode!=13) {
    eedbClearSearchResults(searchSetID);
    return;
  } else if(str.length>2 && charCode==13) {
    return;
  }

  if(!searchDiv) return;

  var searchID   = searchDiv.getAttribute("id");
  var server     = searchDiv.getAttribute("server");
  var peerName   = searchDiv.getAttribute("peer");
  var sources    = searchDiv.getAttribute("sources");
  var mode       = searchDiv.getAttribute("mode");

  var url = eedbSearchServerURL;
  if(peerName) { 
    var peer = eedbGetPeer(peerName);
    if(peer) { url = peer.getAttribute("web_url") + "/cgi/edgeexpress.fcgi"; }
  }
  else if(server) { url = server + "/cgi/edgeexpress.fcgi"; }
  str = str.replace(/[\+]/g,'%2B');
  if(mode == "experiments") {
    url += "?mode=experiments&filter="+str;
  } else {
    url += "?mode=search&limit=1000&name="+str;
    if(sources) { url += ";sources="+sources; }
  }

  var xhr = GetXmlHttpObject();
  if(xhr==null) {
    alert ("Your browser does not support AJAX!");
    return;
  }

  var xhrObj = new Object;
  xhrObj.xhr   = xhr;
  eedb_searchXHR_array[searchID] = xhrObj;


  searchDiv.innerHTML="Searching...";

  //damn this is funky code to get a parameter into the call back funtion
  xhr.onreadystatechange= function(id) { return function() { eedbDisplaySearchResults(id); };}(searchID);
  xhr.open("GET",url,true);
  xhr.send(null);
}


function eedbGetLastSearchResponse(searchID) {
  var xhrObj = eedb_searchXHR_array[searchID];
  var xhr = xhrObj.xhr;
  if(xhr == null) { return; }
  if(xhr.readyState!=4) return;
  if(xhr.status && (xhr.status!=200)) { return; }
  if(xhr.responseXML == null) return;

  var xmlDoc=xhr.responseXML.documentElement;
  if(xmlDoc==null) {
    document.getElementById("message").innerHTML= 'Problem with central DB!';
    return;
  }
  return xmlDoc;
}


function eedbDisplaySearchResults(searchID) {
  var xhrObj = eedb_searchXHR_array[searchID];
  var xhr = xhrObj.xhr;
  if(xhr == null) { return; }
  if(xhr.readyState!=4) return;
  if(xhr.status && (xhr.status!=200)) { return; }
  if(xhr.responseXML == null) return;

  var xmlDoc=xhr.responseXML.documentElement;
  if(xmlDoc==null) {
    document.getElementById("message").innerHTML= 'Problem with central DB!';
    return;
  }

  var searchDiv = document.getElementById(searchID);
  if(!searchDiv) return;
  var peer    = searchDiv.getAttribute("peer");
  var mode    = searchDiv.getAttribute("mode");
  var showAll = searchDiv.getAttribute("showAll");

  var text="<div style=\"font-size:11px;\" onmouseout=\"eedbClearSearchTooltip();\" >";
  var nodes;
  if(peer) { text += "<span style=\"font-weight:bold;color:Navy;\">"+ peer + "::</span> "; }

  if(xmlDoc.getElementsByTagName("result_count")) {
    total     = xmlDoc.getElementsByTagName("result_count")[0].getAttribute("total");
    likeCount = xmlDoc.getElementsByTagName("result_count")[0].getAttribute("like_count");
    filtered  = xmlDoc.getElementsByTagName("result_count")[0].getAttribute("filtered");
  }
  if(total==-1) {
    text += "Error in query";
  } else if(total==0) {
    text += "No match found";
  } else if(total>0 && filtered==0) {
    if(xmlDoc.getElementsByTagName("result_count")[0].getAttribute("method")=='like')
      text += "No match found";
    else
      text += likeCount+" matches : Too many to display";
  } else {
    if(mode == "experiments") {
      nodes = xmlDoc.getElementsByTagName("experiment");
    } else {
      nodes = xmlDoc.getElementsByTagName("match");
    }

    if(showAll == 1) {
      var allnames = "";
      for(i=0; i<nodes.length; i++) allnames += nodes[i].getAttribute("desc")+ " ";
      text += "<a style=\"color:red\" href=\"#\" onclick=\"searchClickAll('" +allnames+ "')\" >(add all " +filtered+ ")</a> ";
    }

    for(i=0; i<nodes.length; i++) {
      var fid   = nodes[i].getAttribute("feature_id");
      var fname = nodes[i].getAttribute("desc");
      if(mode == "experiments") {
        fid = "expt" + nodes[i].getAttribute("id");
        fname = nodes[i].getAttribute("name");
      }
      if(peer) { fid = peer + '::' + fid; }

      text += "<a href=\"#\" " +"onclick=\"searchClick(\'" +fid+ "\', \'" +fname+ "\');return false;\" "
              +" onmouseover=\"eedbSearchTooltip(\'" +fid+ "\');\""
              +">" +fname +"</a> ";
    }
  }

  text += "</div>";
  searchDiv.innerHTML=text;
}


function eedbSearchTooltip(id) {

  var mode = "feature";

  var re = /^(.+)\:\:(.+)$/;
  var mymatch = re.exec(id);
  var peer;
  if(mymatch && (mymatch.length == 3)) {
    id   = mymatch[2];
    peer = eedbGetPeer(mymatch[1]);
  }

  var re2 = /^expt(.+)$/;
  var mymatch2 = re2.exec(id);
  if(mymatch2 && (mymatch2.length == 2)) {
    mode="experiments";
    id  = mymatch2[1];
  }

  var url = eedbSearchServerURL;
  if(peer) { url = peer.getAttribute("web_url") + "/cgi/edgeexpress.fcgi"; }
  url += "?mode=" + mode + ";id=" + id;
  //document.getElementById("message").innerHTML= url;

  featureTipXMLHttp=GetXmlHttpObject();
  if(featureTipXMLHttp==null) {
    alert ("Your browser does not support AJAX!");
    return;
  }

  featureTipXMLHttp.onreadystatechange=eedbDisplaySearchTooltip;
  featureTipXMLHttp.open("GET",url,false);
  featureTipXMLHttp.send(null);
  eedbDisplaySearchTooltip();
}

function eedbClearSearchTooltip() {
  if(ns4) toolTipSTYLE.visibility = "hidden";
  else toolTipSTYLE.display = "none";
  // document.getElementById("SVGdiv").innerHTML= "tooltip mouse out";
}

function eedbDisplaySearchTooltip(id) {
  if(featureTipXMLHttp.readyState!=4) return;
  if(featureTipXMLHttp.responseXML == null) return;

  var xmlDoc=featureTipXMLHttp.responseXML.documentElement;
  if(xmlDoc==null) {
    alert('Problem with central DB!');
    return;
  } 

  if(xmlDoc.getElementsByTagName("feature")) {
    var feature = xmlDoc.getElementsByTagName("feature")[0];
    eedbFeatureTooltip(feature);
  }
  if(xmlDoc.getElementsByTagName("experiment")) {
    var experiment = xmlDoc.getElementsByTagName("experiment")[0];
    eedbExperimentTooltip(experiment);
  }

}


function eedbFeatureTooltip(feature) {
  if(!feature) return;
  var fsource = feature.getElementsByTagName("featuresource")[0];
  var symbols = feature.getElementsByTagName("symbol");
  var mdata = feature.getElementsByTagName("mdata");
  var maxexpress = feature.getElementsByTagName("max_expression");
  var synonyms = "";
  var description = "";
  var entrez_id;
  var genloc = "";
  var chromloc = feature.getAttribute("chr") +":" 
                +feature.getAttribute("start") +".." 
                +feature.getAttribute("end")
                +feature.getAttribute("strand");

  for(i=0; i<mdata.length; i++) {
    if(mdata[i].getAttribute("type") == "description") description = mdata[i].firstChild.nodeValue; 
  }
  for(i=0; i<symbols.length; i++) {
    if(symbols[i].getAttribute("type") == "ILMN_hg6v2_key") {
      synonyms += symbols[i].getAttribute("value") + " ";
    }
    if(symbols[i].getAttribute("type") == "Entrez_synonym") {
      synonyms += symbols[i].getAttribute("value") + " ";
    }
    if((symbols[i].getAttribute("type") == "EntrezGene") && (feature.getAttribute("desc") != symbols[i].getAttribute("value"))) {
      synonyms += symbols[i].getAttribute("value") + " ";
    }
    if(symbols[i].getAttribute("type") == "EntrezID") entrez_id = symbols[i].getAttribute("value");
    if(symbols[i].getAttribute("type") == "GeneticLoc") genloc = symbols[i].getAttribute("value");
    if(symbols[i].getAttribute("type") == "TFsymbol") synonyms += symbols[i].getAttribute("value");
  }
  var object_html = "<div style=\"text-align:left; font-size:10px; font-family:arial,helvetica,sans-serif; "+
                    "width:300px; z-index:100; "+
                    "background-color:lavender; border:inset; padding: 3px 3px 3px 3px;"+
                    "opacity: 0.95; filter:alpha(opacity=95); -moz-opacity:0.95;\">";
  object_html += "<div><span style=\"font-size:12px; font-weight: bold;\">" + feature.getAttribute("desc")+"</span>";
  object_html += " <span style=\"font-size:9px;\">" + fsource.getAttribute("category") +" : " + fsource.getAttribute("name") + "</span>";
  object_html += "</div>";
  if(description.length > 0) object_html += "<div>" +description+ "</div>";
  if(synonyms.length > 0) object_html += "<div>alias: " + synonyms +"</div>";
  if(entrez_id) object_html += "<div>EntrezID: " + entrez_id +"</div>";
  object_html += "<div>location: " + genloc + " ::  " + chromloc +"</div>";
  object_html += "<div>maxexpress: ";
  if(maxexpress && (maxexpress.length > 0)) {
    var express = maxexpress[0].getElementsByTagName("express");
    for(i=0; i<express.length; i++) {
      var platform = express[i].getAttribute("platform");
      if(platform == 'Illumina microarray') { platform = "ILMN"; }
      object_html += platform + ":" + express[i].getAttribute("maxvalue") + " ";
    }
  }
  object_html += "</div>";

  object_html += "</div>";

  if(ns4) {
    toolTipSTYLE.document.write(object_html);
    toolTipSTYLE.document.close();
    toolTipSTYLE.visibility = "visible";
  }
  if(ns6) {
    //document.getElementById("toolTipLayer").innerHTML;
    document.getElementById("toolTipLayer").innerHTML = object_html;
    toolTipSTYLE.display='block'
  }
  if(ie4) {
    document.all("toolTipLayer").innerHTML=object_html;
    toolTipSTYLE.display='block'
  }
}


function eedbExperimentTooltip(experiment) {
  if(!experiment) return;

  var symbols = experiment.getElementsByTagName("symbol");
  var mdata = experiment.getElementsByTagName("mdata");
  var description = "";
  var exp_name = experiment.getAttribute("name");
  exp_name = exp_name.replace(/_/g, " ");

  for(i=0; i<mdata.length; i++) {
    if(mdata[i].getAttribute("type") == "description") description = mdata[i].firstChild.nodeValue; 
  }
  var object_html = "<div style=\"text-align:left; font-size:10px; font-family:arial,helvetica,sans-serif; "+
                    "width:300px; z-index:100; "+
                    "background-color:lavender; border:inset; padding: 3px 3px 3px 3px;"+
                    "opacity: 0.9; filter:alpha(opacity=90); -moz-opacity:0.9;\">";
  object_html += "<div><span style=\"font-size:12px; font-weight: bold;\">" +exp_name+ "</span>";
  object_html += " <span style=\"font-size:9px;\">" + experiment.getAttribute("platform") +" : experiment</span>";
  object_html += "</div>";
  if(description.length > 0) object_html += "<div>" +description+ "</div>";

  object_html += "<table cellpadding=\"0px\">";
  for(i=0; i<symbols.length; i++) {
    var type = symbols[i].getAttribute("type");
    var value = symbols[i].getAttribute("value");
    object_html += "<tr><td>" +type+ "</td><td>" +value+ "</td></tr>";
  }
  object_html += "</table>";

  object_html += "</div>";

  if(ns4) {
    toolTipSTYLE.document.write(object_html);
    toolTipSTYLE.document.close();
    toolTipSTYLE.visibility = "visible";
  }
  if(ns6) {
    //document.getElementById("toolTipLayer").innerHTML;
    document.getElementById("toolTipLayer").innerHTML = object_html;
    toolTipSTYLE.display='block'
  }
  if(ie4) {
    document.all("toolTipLayer").innerHTML=object_html;
    toolTipSTYLE.display='block'
  }
}


function eeebConfigSearchSet(searchSetID) {
  var searchset = document.getElementById(searchSetID);
  if(!searchset) { return; }
  var searchDivs = allBrowserGetElementsByClassName(searchset,"EEDBsearch");

  var divFrame = document.createElement('div');
  divFrame.setAttribute('id', "searchSetConfigDiv");
  divFrame.setAttribute('style', "position:absolute; background-color:LightYellow; text-align:left; "
                            +"border:inset; border-width:1px; padding: 3px 3px 3px 3px; "
                            +"z-index:102; opacity: 0.9; filter:alpha(opacity=90); -moz-opacity:0.9; "
                            +"left:" + (toolTipSTYLE.xpos-229) +"px; "
                            +"top:" + toolTipSTYLE.ypos +"px; "
                            +"width:320px;"
                             );
  for(i=0; i<searchDivs.length; i++) {
    var searchDiv = searchDivs[i];

    var searchID   = searchDiv.getAttribute("id");
    var server     = searchDiv.getAttribute("server");
    var peerName   = searchDiv.getAttribute("peer");
    var sources    = searchDiv.getAttribute("sources");
    var mode       = searchDiv.getAttribute("mode");

    //----------
    var button = document.createElement('input');
    button.setAttribute("type", "button");
    button.setAttribute("value", "delete");
    button.setAttribute('style', "float:right; margin: 0px 4px 4px 4px;");
    button.setAttribute("onclick", "eedbReconfigSearchParam(\""+ searchID+"\", 'delete');");
    divFrame.appendChild(button);

    var div1 = document.createElement('div');
    div1.setAttribute('style', "font-size:10px; font-family:arial,helvetica,sans-serif;");
    div1.innerHTML = "peer: " + peerName;
    divFrame.appendChild(div1)

    div1 = document.createElement('div');
    div1.setAttribute('style', "font-size:10px; font-family:arial,helvetica,sans-serif;");
    div1.innerHTML = "source filter: " + sources;
    divFrame.appendChild(div1)

    divFrame.appendChild(document.createElement('hr'));
  }

  var button1 = document.createElement('input');
  button1.setAttribute("type", "button");
  button1.setAttribute("value", "cancel");
  button1.setAttribute('style', "float:left; margin: 0px 4px 4px 4px;");
  button1.setAttribute("onclick", "eedbReconfigSearchParam(\""+ searchID+"\", 'cancel');");
  divFrame.appendChild(button1);

  var button3 = document.createElement('input');
  button3.setAttribute("type", "button");
  button3.setAttribute("value", "accept config");
  button3.setAttribute('style', "float:right; margin: 0px 4px 4px 4px;");
  button3.setAttribute("onclick", "eedbReconfigSearchParam(\""+ searchID+"\", 'accept-reconfig');");
  divFrame.appendChild(button3);

  searchset.appendChild(divFrame);
}


function eedbReconfigSearchParam(searchSetID, searchID, param, value) {
  //document.getElementById("message").innerHTML= "reconfig: " + searchID + ":: "+ param + "="+value;
  var searchset = document.getElementById(searchSetID);
  if(!searchset) { return; }
  var searchDiv = searchset.getElementById(searchSetID);
  if(!searchDiv) { return; }

  var newconfig = new Object; //need to make this real

  if(param == "peer") {
    //searchDiv.setAttribute("peer", value);
  }

  if(param == "cancel-reconfig") {
  }

  if(param == "accept-reconfig") {
  }
}


