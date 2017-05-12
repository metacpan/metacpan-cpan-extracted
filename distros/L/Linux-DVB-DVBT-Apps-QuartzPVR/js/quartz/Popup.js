/**
 * Popup.js: simple CSS popups with drop shadows.
 * 
 * This module defines a Popup class. Create a Popup object with the 
 * Popup() constructor.  Then make it visible with the show() method.
 * When done, hide it with the hide() method.
 *
 * Note that this module must be used with appropriate CSS class definitions
 * to display correctly.  The following are examples.
 * 
 *   .popupContent {
 *      left: -4px; top: -4px;        /* how much of the shadow shows * /
 *      background-color: #ff0;       /* yellow background * /
 *      border: solid black 1px;      /* thin black border * /
 *      padding: 5px;                 /* spacing between text and border * /
 *      font: bold 10pt sans-serif;   /* small bold font * /
 *   }
 *
 */
function Popup() {  // The constructor function for the Popup class
	this.popup = null ;
	this.margin = 30 ; // need enough to ensure we can see it all, but not too much so it cycles on/off
}

// Set the content and position of the popup and display it
Popup.prototype.show = function(content, x, y, width) 
{

	if (this.popup == null)
	{
	    this.popup = document.createElement("div"); // create div for content
	    this.popup.style.position = "absolute";     // absolutely positioned
	    this.popup.style.visibility = "hidden";     // starts off hidden
	    this.popup.className = "popupContent";     // so we can style it
	}
	
	if (typeof content == "string")
	{
    	this.popup.innerHTML = content;             // Set the text of the popup.
    }
    else
    {
    	// remove existing
		while( this.popup.hasChildNodes() ) 
		{ 
			this.popup.removeChild( this.popup.lastChild ); 
		}
		    	
    	// append node
    	this.popup.appendChild(content) ;
    }
    this.popup.style.left = x + "px";        // Set the position.
    this.popup.style.top = y + "px";
    this.popup.style.zIndex = 100;     // top of the heap
    this.popup.style.visibility = "visible"; // Make it visible.
    if (!width) width=300 ;
    this.popup.style.width = width+"px" ; 
    this.popup.style.visibility = "visible"; // Make it visible.

    // Add the popup to the document if it has not been added before
    if (this.popup.parentNode != document.body)
        document.body.appendChild(this.popup);
};

// Hide the popup
Popup.prototype.hide = function() {

	if (this.popup != null)
	{
	    this.popup.style.visibility = "hidden";  // Make it invisible.
        document.body.removeChild(this.popup);
        this.popup = null ;
	}
};

/*------------------------------------------------------------------------------------------------------*/
//Adjust x & y values to ensure popup is on screen 
//
Popup.prototype.adjustXY = function(x, y)
{
	if (this.popup == null)
		return ;

	var viewableDims = Geometry.viewableArea() ;
	
	// Check we haven't gone over the edge - as popup drops down from the on-screen node (has to be on-screen otherwise
	// we can't click it!) then just check bottom of popup hasn't gone past the end of the viewable area
	//
	// top:--------------
	//   ...
	//   y:
	//    | pop_height
	//    v
	//    -
	//
	//
	//bot:------------------
	//
	var pop_height = this.popup.scrollHeight ;
	if (y + pop_height + this.margin > viewableDims.bottomRight.y)
	{
		y = viewableDims.bottomRight.y - pop_height - this.margin ;
		if (y < viewableDims.topLeft.y) y=viewableDims.topLeft.y ;
		this.popup.style.top = y + "px";
	}
	
	var pop_width = this.popup.scrollWidth ;
	if (x + pop_width + this.margin > viewableDims.bottomRight.x)
	{
		x = viewableDims.bottomRight.x - pop_width - this.margin ;
		if (x < viewableDims.topLeft.x) x=viewableDims.topLeft.x ;
		this.popup.style.left = x + "px";
	}
	if (x < viewableDims.topLeft.x)
	{
		x = viewableDims.topLeft.x ;
		this.popup.style.left = x + "px";
	}

}