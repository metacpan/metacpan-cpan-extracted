// Migrate to JQuery

var Geometry = {} ;

// Get coords of viewable area, returns object contining top left and bottom right corners
// Takes into account viewport scrolling
Geometry.viewableArea = function () {
	
	var vscroll = $(document).scrollTop() ;
	var hscroll = $(document).scrollLeft() ;
	
	var width = $(window).width() ;
	var height = $(window).height() ;
	
	var dims = {
		height  : height,
		width   : width,
		hscroll : hscroll,
		vscroll : vscroll,
		topLeft : {
			x : hscroll,
			y : vscroll
		},
		bottomRight : {
			x : hscroll + width,
			y : vscroll + height
		}
	} ;
	
	return dims ;
}

