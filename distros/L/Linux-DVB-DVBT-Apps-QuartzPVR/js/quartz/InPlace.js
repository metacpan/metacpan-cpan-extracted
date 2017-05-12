// Based on the ideas in http://tool-man.org/examples/edit-in-place.html
// Tim Taylor Consulting 
/*
 * 
 * 
 * 
HTML:

.inplace {
	position: absolute;
	visibility: hidden;
	z-index: 10000;
}
 <input id="a3Edit" class="inplace" name="a3Edit">
 <ul id="list3" class="sortable boxy">
<li>
<div id="a3View" class="view">alpha</div>
</li>

SCRIPT:

onload() {

	join("a3")

}

 * 
 * 
 */
var InPlace = {} ;

InPlace.ID = 0 ;
InPlace.EDITORS = {} ;

/*------------------------------------------------------------------------------------------------------*/
// Close any shown popups
InPlace.closeAll = function()
{
	for (var id in InPlace.EDITORS)
	{
		var popupHide = InPlace.EDITORS[id] ;
		popupHide() ;
	}
}



// Constants
InPlace.ESCAPE = 27 ;
InPlace.ENTER = 13 ;
InPlace.TAB = 9 ;


//----------------------------------------------------------------------------------------------
// Given a DOM node (used for displaying the text), create an editor and link them
InPlace.add_inplace = function(node, callback, userData) 
{
	// Initial setup
	if (!node.hasOwnProperty("editor"))
	{
		var edit = document.createElement("input");
		edit.className = "inplace" ;
		edit.style.position = "absolute" ; 
		edit.style.visibility = "hidden" ; 
		edit.style.zindex = "10000" ; 
		document.body.appendChild(edit);
		
		node.editor = edit ;
	}
	var view = node ;
	var editor = view.editor ;
	
	view.callback = callback ;
	view.userData = userData ;

	// Prepare for popup handler
	var inplaceSettings = {
		
		//-----------------------------------------------------
		create_popup: function(settings, x, y, callback) {
			return view ;
		},
		//-----------------------------------------------------
		popup_node	: function(settings, popupObj) {
			var view = popupObj ;
			var editor = view.editor
			return editor ;
		},
		//-----------------------------------------------------
		show_popup	: function(settings, popupObj, x, y) {
			
			var view = popupObj ;
			var editor = view.editor

    		if (!editor) return true ;

    		if (editor.currentView != null) {
    			editor.blur()
    		}
    		editor.currentView = view

    		editor.style["top"] = y + "px" ;
    		editor.style["left"] = x + "px" ;
    		
			editor.style['width'] = view.offsetWidth + "px"
			editor.style['height'] = view.offsetHeight + "px"

    		editor.value = view.innerHTML
    		editor.style['visibility'] = 'visible'
    		view.style['visibility'] = 'hidden'
    			
    		editor.abandonChanges = false
    		editor.focus()
			
		},
		//-----------------------------------------------------
		// This is called by PopupHandler - only called when moused out
		hide_popup	: function(settings, popupObj) {

			var view = popupObj ;
			if (!view)
			{
				var dummy = 1 ;
			}
			else
			{
				var editor = view.editor
				editor.abandonChanges = true

				// Handle close of edit - hide popup and call callback with value
				editor.blur();
			}
		},
		//-----------------------------------------------------
		callback	: function(settings, vars) {
			
			// NOT USED - view.editor.onblur() handles callbacks
			var dummy = 1 ;
		}
	} ;
	
	// Add event handling for popup
	var hidePopup = PopupHandler.add_popup(node, inplaceSettings) ;

	// Now add this instance to the list
	var id = InPlace.ID++ ;
	InPlace.EDITORS[id] = hidePopup ;
	
	//--------------------------------------------------------------------------
	// Node view event handlers
	//--------------------------------------------------------------------------

	//---------------------------------------------------------
	view.editor.onblur = function(event) {

log.debug("Inplace.onblur()") ;

		var editor = event.target
		var view = editor.currentView

		var value = editor.value ;

		// call callback
		if (!editor.abandonChanges) 
		{
			view.innerHTML = value ;
			if (view.callback)
			{
				// call function with new value
				view.callback(view.userData, value) ;
			}
		}

		editor.abandonChanges = false
		editor.style['visibility'] = 'hidden'
		editor.value = '' // fixes firefox 1.0 bug
		view.style['visibility'] = 'visible'
		editor.currentView = null

		return true
	}
	
	//---------------------------------------------------------
	view.editor.onkeydown = function(event) {
		
		var editor = event.target ;
log.debug("Inplace.onkeydown() key="+event.keyCode) ;
		if ((event.keyCode == InPlace.TAB) || (event.keyCode == InPlace.ENTER)) {
			editor.blur()
			return false
		}
	}

	//---------------------------------------------------------
	view.editor.onkeyup = function(event) {

		var editor = event.target ;
		
log.debug("Inplace.onkeyup() key="+event.keyCode) ;

		if (event.keyCode == InPlace.ESCAPE) {
			editor.abandonChanges = true
			editor.blur()
			return false
		} else if (event.keyCode == InPlace.TAB) {
			editor.abandonChanges = false
			return false
		} else if (event.keyCode == InPlace.ENTER) {
			editor.abandonChanges = false
			return false
		} else {
			return true
		}
	}
	
}

