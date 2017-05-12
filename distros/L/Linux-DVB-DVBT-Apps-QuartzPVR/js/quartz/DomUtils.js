/*
DOM element utilities

*/

// Migrate to JQuery

// Make sure we haven't already been loaded
var DomUtils;
if (DomUtils && (typeof DomUtils != "object" || DomUtils.NAME))
    throw new Error("Namespace 'DomUtils' already exists");

// Create our namespace, and specify some meta-information
DomUtils = {};
DomUtils.NAME = "DomUtils";    // The name of this namespace
DomUtils.VERSION = 1.0;    // The version of this namespace


//-----------------------------------------------------------------------------
//Adjust the node's width by the specified delta (+-)
DomUtils.incWidth = function (node, delta) 
{
	$(node).width( $(node).width() + delta ) ;
}

//-----------------------------------------------------------------------------
//Adjust the nodes width (and all of it's children) by the specified delta (+-)
DomUtils.incChildWidths = function (node, delta) 
{
	$(node).width( $(node).width() + delta ) ;
	$("*", $(node)).each(function() { 
		$(this).width( $(this).width() + delta ) 
	}) ;
}


