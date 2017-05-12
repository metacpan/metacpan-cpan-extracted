/**
 * ClickHandler.js: event handler factory for "popups" (that are displayed/hidden by clicking a node).
 * 
 *
 */
// The constructor function for the ClickHandler class
function ClickHandler() {}

ClickHandler.ID = 0 ;
ClickHandler.POPUPS = {} ;

/*------------------------------------------------------------------------------------------------------*/
// Close any shown popups
ClickHandler.closeAll = function()
{
	for (var id in ClickHandler.POPUPS)
	{
		var popupHide = ClickHandler.POPUPS[id] ;
		popupHide() ;
	}
}


/*------------------------------------------------------------------------------------------------------*/
// Add a popup window to a DOM node - shows the window when moused over
//
//settings object must contain:
//	
//	settings.create_popup(settings, x, y, callback) 		Return a popup object
//	settings.popup_node(settings, popup) 					Get the DOM node from the popup
//	settings.show_popup(settings, popup, x, y)				Display popup
//	settings.hide_popup(settings, popup)					Hide it again
//	settings.callback(settings, vars) 						The callback to be called when values change
//
ClickHandler.add_popup = function(node, settings)
{
	//---------------------------------------------------------------------------------------------
	// This is the function that adds event handlers
	function addPopupToNode(link) 
	{
		// Add event handlers 
		$(link).click(click) ;
		
		// Keep track of this instance's popup
		var popup ;
		var popupNode ;
		var popupShow = 0 ;

		//----------------------------------------------------------------------------------------
		// Main node click - show/hide popup
		function click(event) 
		{
log.debug("ClickHandler.clicked popup");		
			event.stopPropagation() ;
			
			if (!popupShow)
			{
				showPopup() ;
			}
			else
			{
				hidePopup() ;
			}
		}

		//-----------------------------------------------------------------------------
		function showPopup() 
		{
			log.debug("ClickHandler.showPopup()");		
			// get coords of link
			var margin = 20 ;
			var pos = $(link).offset() ;
			var x = pos.left + margin;
			var y = pos.top + margin;
			
			if (x < 0) x = 0 ;
			if (y < 0) y = 0 ;

			log.debug(" + x="+x+" y="+y);		

			// Create the popup object - tell it the callback routine to be called
			popup = settings.create_popup(settings, x, y, callback) ;
			popup.margin = margin ;
			
			// Show the popup window
			settings.show_popup(settings, popup, x, y);
         
			// Retrieve the DOM object to be used for the popup
			// NOTE: Do this AFTER showing to ensure object has been created
			popupNode = settings.popup_node(settings, popup) ;
			
			popupShow = 1 ;

			log.debug(" + popupShow="+popupShow);		
		}
		
		//----------------------------------------------------------------------------------------
		function hidePopup() 
		{
			log.debug("ClickHandler.hidePopup()");		
			// Call callback to hide the popup window
			settings.hide_popup(settings, popup);
			
			popupShow = 0 ;
		}

	    //----------------------------------------------------------------------------
	    // Callback handler - called from popup contents - needs to be passed any changed vars
		function callback(vars) 
		{
			log.debug("ClickHandler.callback()");		
			// Close the popup BEFORE calling callback - callback may cause the DOM to be changed
			hidePopup() ;

			// Activate the real callback
			settings.callback(settings, vars) ;
		}
		
		// return a ref to the popup hide routine
		return hidePopup ;
	}
	
	// Add popup
	var hideFunction = addPopupToNode(node);

	// Now add this instance to the list
	var id = ClickHandler.ID++ ;
	ClickHandler.POPUPS[id] = hideFunction ;
}

