// (C) 2009 Magna Powertrain
// contact: Rene Schickbauer

// This script file holds various helper functions
// commonly used in Maplat forms


function setMode(elemID, modeVal) {
    var modeElem = document.getElementById(elemID);
    modeElem.value = modeVal;
    return true;
}

function serializeList(listID, inputID) {
	var listElems = $(listID).sortable('toArray');
	var listString = listElems.join(";");
	var modeElem = document.getElementById(inputID);
	modeElem.value = listString;
	return true;
}