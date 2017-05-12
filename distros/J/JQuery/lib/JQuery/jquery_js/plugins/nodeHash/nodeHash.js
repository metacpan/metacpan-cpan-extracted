/*
 * Don't use this! It's alpha!
 * Copyright 2006 by Paul Bakaus.
 */
function nodeHash(what) {
	var curParent = $(what)[0].parentNode;
	var child = $(what)[0];
	var nHash = [];
	
	do {
		nHash.push($("*",curParent).index(child));
		child = curParent;
		curParent = curParent.parentNode;				
	} while(curParent);
	
	nHash.reverse();
	return nHash.join(".");
}
function getElementByHash(nHash) {
	nHash = nHash.split(".");
	for(var i=0;i<nHash.length;i++) {
		nHash[i] = "*:eq("+nHash[i]+")";
	}
	return $(nHash.join(" "));
}