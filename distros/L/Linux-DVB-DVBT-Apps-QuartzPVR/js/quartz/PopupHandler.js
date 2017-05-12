/**
 * PopupHandler.js: event handler factory for popups.
 * 
 *
 */
// The constructor function for the PopupHandler class
function PopupHandler() {}  

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
PopupHandler.add_popup = function(node, settings)
{
	//---------------------------------------------------------------------------------------------
	// This is the function that adds event handlers
	function addPopupToNode(link) 
	{
		// Add event handlers 
		$(link).mouseover(mouseover) ;
		$(link).mouseout(mouseout) ;
		
		var timer; // Used with setTimeout/clearTimeout
		var timerOff ;
		
		// Keep track of this instance's popup
		var popup ;
		var popupNode ;

		//----------------------------------------------------------------------------------------
		// Main node mouseover - show popup
		function mouseover(event) 
		{
			log.debug("mouseover popup");		

			// get coords of link
			var pos = $(link).offset() ;
			var x = pos.left ;
			var y = pos.top ;
			
			if (x < 0) x = 0 ;
			if (y < 0) y = 0 ;

			// If a hide popup is pending, cancel it
			if (timerOff) 
			{
			 	window.clearTimeout(timerOff);
			 	timerOff = null ;
			 	hidePopup() ;
			}
			
			// If a popup is pending, cancel it
			if (timer) window.clearTimeout(timer);
			
			// Schedule a popup to appear in half a second
			timer = window.setTimeout(showPopup, 500);

			//-----------------------------------------------------------------------------
			function showPopup() 
			{
				log.debug("show popup");		
				// Create the popup object - tell it the callback routine to be called (which is this one below)
				popup = settings.create_popup(settings, x, y, callback) ;
				
				// Show the popup window
				settings.show_popup(settings, popup, x, y);
             
				// Retrieve the DOM object to be used for the popup
				// NOTE: Do this AFTER showing to ensure object has been created
				popupNode = settings.popup_node(settings, popup) ;
				
		        // Add event handlers 
				$(popupNode).mouseover(popup_mouseover) ;
				$(popupNode).mouseout(popup_mouseout) ;

		        // Propagate 'mouseover' handler down to all popup children - otherwise we get a 'mouseout' as soon as we 
		        // move from the popup background on to one of it's children div's etc.
		        for (var child in popupNode.getElementsByTagName('*'))
		        {
		        	if (child.nodeType == 1 /* Node.ELEMENT_NODE */)
		        	{
						$(child).mouseover(popup_mouseover) ;
		        	}
		        }
			}
		}

		//----------------------------------------------------------------------------------------
		// Main node mouseout
		function mouseout(event) 
		{
			log.debug("mouseout popup");		
			// If a popup is pending, cancel it
			if (timerOff) window.clearTimeout(timerOff);
			
			// Schedule popup to close in half a second
			timerOff = window.setTimeout(hidePopup, 500);
			
			// When the mouse leaves a link, clear any 
			// pending popups or hide it if it is shown
			if (timer) window.clearTimeout(timer);
			timer = null;
		}

		//----------------------------------------------------------------------------------------
		// Popup child mouseover
		function popup_mouseover(event) 
		{
			// If a hide popup is pending, cancel it
			if (timerOff) 
			{
			 	window.clearTimeout(timerOff);
			 	timerOff = null ;
			}
			
			// If a popup is pending, cancel it
			if (timer) window.clearTimeout(timer);
		}

		//----------------------------------------------------------------------------------------
		// Popup child mouseover
		function popup_mouseout(event) 
		{
			// If a popup hide is pending, cancel it
			if (timerOff) window.clearTimeout(timerOff);
			
			// Schedule popup to close in half a second
			timerOff = window.setTimeout(hidePopup, 500);
			
			// When the mouse leaves a link, clear any 
			// pending popups or hide it if it is shown
			if (timer) window.clearTimeout(timer);
			timer = null;
		}

		//----------------------------------------------------------------------------------------
		function hidePopup() 
		{
			// Call callback to hide the popup window
			settings.hide_popup(settings, popup);
			
			// If a popup hide is pending, cancel it
			if (timerOff) window.clearTimeout(timerOff);
			// If a popup show is pending, cancel it
			if (timer) window.clearTimeout(timer);
		}

	    //----------------------------------------------------------------------------
	    // Callback handler - called from popup contents - needs to be passed any changed vars
		function callback(vars) 
		{
			// Close the popup BEFORE calling callback - callback may cause the DOM to be changed
			hidePopup() ;

			// Activate the real callback as specified
			settings.callback(settings, vars) ;
		}
		
		// useful for global close of all popups
		return hidePopup ;
	}

	// Add the popup
	var hidePopup = addPopupToNode(node);

	return hidePopup ;
}

