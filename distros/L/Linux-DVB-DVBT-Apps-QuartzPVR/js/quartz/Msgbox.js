/**
 * Create a message box from a Dialog
 *
 */
function Msgbox() {  // The constructor function for the Msgbox class

	var width = 400 ;
	var height = 400 ;
	this.width = width ;
	this.height = height ;
	
	this.msgbox = new Dialog({
		title: 'Message', 
		className : 'msgbox',
		width: width,
//		height: height,
		content: "",
		buttons: [
			{
				label: 'Close',
				type: 'ok'
			}
		]
	}) ;

}

// Set the content and position of the msgbox and display it
Msgbox.prototype.show = function(title, content, x, y, id) 
{
	this.msgbox.setTitle(title) ;
	this.msgbox.setContent(content) ;
	id = id || "message" ;
	this.msgbox.setId(id) ;
	
	// x & y set the center point of the message box - i.e. if x & y are set to the screen width/2 and screen height/2 then box is centered in screen
	x = x || (this.width/2) ;
	y = y || (this.height/2) ;
	
	var left = x - (this.width/2) ;
	if (left < 0) left=0 ;
	var top = y - (this.height/2) ;
	if (top < 0) top=0 ;
	
	this.msgbox.show(left, top) ;
}

//Set the content and display in centre of viewable area
Msgbox.prototype.showCentral = function(title, content, id) 
{
	this.msgbox.setTitle(title) ;
	this.msgbox.setContent(content) ;
	id = id || "message" ;
	this.msgbox.setId(id) ;
	
	this.msgbox.showCentral() ;
}



// Hide the msgbox - should happen automatically due to button
Msgbox.prototype.hide = function() {

	this.msgbox.hide() ;
}

// Utility
Msgbox.prototype.msg = function(content) { this.showCentral("Message", content, "message") ; }
Msgbox.prototype.info = function(content) { this.showCentral("Info", content, "info") ; }
Msgbox.prototype.warn = function(content) { this.showCentral("Warning", content, "warn") ; }
Msgbox.prototype.error = function(content) { this.showCentral("Error", content, "error") ; }

