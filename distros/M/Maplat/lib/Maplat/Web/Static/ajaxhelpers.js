var http = false;
var srefresh = false;
var srefreshurl = '';
var srefreshfield = '';

if(navigator.appName == "Microsoft Internet Explorer") {
  http = new ActiveXObject("Microsoft.XMLHTTP");
  srefresh = new ActiveXObject("Microsoft.XMLHTTP");
} else {
  http = new XMLHttpRequest();
  srefresh = new XMLHttpRequest();
} 

function ajaxUpdateInputField(FieldButton, FieldName, TargetUrl) {
  FieldButton.disabled = true;
  var myInp = document.getElementById(FieldName);
  myInp.disabled = true;
  http.open("GET", TargetUrl, true);
  http.onreadystatechange=function() {
    if(http.readyState == 4) {
	  myInp.value = http.responseText;
	  myInp.disabled = false;
	  FieldButton.disabled = false;
    }
  }
  http.send(null);
}

function ajaxUpdateSessionField() {
  var myInp = document.getElementById(srefreshfield);
  srefresh.open("GET", srefreshurl, true);
  srefresh.onreadystatechange=function() {
    if(srefresh.readyState == 4) {
	  myInp.innerHTML = srefresh.responseText;
    }
  }
  srefresh.send(null);
  setTimeout("ajaxUpdateSessionField()", 120000);
}

function startSessionRefresh(FieldName, TargetUrl) {
  srefreshfield = FieldName;
  srefreshurl = TargetUrl;
  setTimeout("ajaxUpdateSessionField()", 120000);
}

function ajaxSetInputField(FieldName, FieldValue) {
  var myInp = document.getElementById(FieldName);
  myInp.value = FieldValue;
}

function ajaxCheckHideElement(SrcElemName, DestElemName, EnabledValue) {
  var mySrc = document.getElementById(SrcElemName);
  var myDest = document.getElementById(DestElemName);
  if(mySrc.value == EnabledValue) {
	myDest.style.visibility = "visible";
  } else {
	myDest.style.visibility = "hidden";
  }
  return true;
}

function ajaxUpdateInputFieldWithCheck(FieldButton, FieldName, TargetUrl, CheckElemName, CheckValue) {
  FieldButton.disabled = true;
  var myInp = document.getElementById(FieldName);
  myInp.disabled = true;
  http.open("GET", TargetUrl, true);
  http.onreadystatechange=function() {
    if(http.readyState == 4) {
	  myInp.value = http.responseText;
	  myInp.disabled = false;
	  FieldButton.disabled = false;
	  var myDest = document.getElementById(CheckElemName);
	  if(myInp.value == CheckValue) {
		myDest.style.visibility = "visible";
	  } else {
		myDest.style.visibility = "hidden";
	  }
    }
  }
  http.send(null);
}