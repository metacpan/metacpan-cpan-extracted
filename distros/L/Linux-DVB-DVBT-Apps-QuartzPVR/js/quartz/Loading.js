/**
 * Loading.js: show 'loading/waiting' image
 * 
 * Requires: Geometry.js
 *
 * This module defines a Loading class. Create a Loading object with the 
 * Loading() constructor.  Then make it visible with the show() method.
 * When done, hide it with the hide() method.
 *
 *
 */
function Loading(imgname, settings) {  // The constructor function for the Loading class

	if (!settings) settings = {} ;
	this.settings = settings ;

	this.loading = document.createElement("div");
    this.loading.style.position = "absolute";     // absolutely positioned
    this.loading.style.visibility = "hidden";     // starts off hidden
    this.loading.className = "loading";     	  // so we can style it
    
    this.image = new Image() ;
	this.image.src = imgname ;
	
	this.loadingDiv = document.createElement("div");
    this.loadingDiv.className = "loadingContent";     	  // so we can style it
	this.loading.appendChild(this.loadingDiv) ;

	this.loadingImg = document.createElement("img");
	this.loadingDiv.appendChild(this.loadingImg) ;	
}

// Set the position of the loading window and display it
Loading.prototype.show = function() 
{
	this.loadingImg.src = this.image.src ;
	
	// calc size based on settings
	if (!this.settings.height) this.settings.height = this.image.height ;
	if (!this.settings.width) this.settings.width = this.image.width ;
	if (!this.settings.margin) this.settings.margin = 0 ;
	
	this.loading.style.height = this.settings.height+(2*this.settings.margin)+'px' ;
	this.loading.style.width = this.settings.width+(2*this.settings.margin)+'px' ;

	if (this.settings.margin > 0) 
		this.loadingDiv.style.margin = this.settings.margin+'px' ;

	// Set the position.
	var viewableDims = Geometry.viewableArea() ;
	var x = parseInt((viewableDims.width - this.image.width) / 2, 10) + viewableDims.topLeft.x ;
	var y = parseInt((viewableDims.height - this.image.height) / 2, 10) + viewableDims.topLeft.y ;
    this.loading.style.left = x + "px";        
    this.loading.style.top = y + "px";

    this.loading.style.zIndex = 100;     // top of the heap
    this.loading.style.visibility = "visible"; // Make it visible.

    // Add the loading to the document if it has not been added before
    if (this.loading.parentNode != document.body)
        document.body.appendChild(this.loading);
};

// Hide the loading
Loading.prototype.hide = function() {

    this.loading.style.visibility = "hidden";  // Make it invisible.
    if (this.loading.parentNode == document.body)
    	document.body.removeChild(this.loading);
};
