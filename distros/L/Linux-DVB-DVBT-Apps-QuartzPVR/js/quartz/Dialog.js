/**
 * Dialog.js: a general controllable dialog box.
 * 
 * This module defines a Dialog class. Create a Dialog object with the 
 * Dialog() constructor.  Then make it visible with the show() method.
 * When done, hide it with the hide() method.
 *
 * Creates the structure:
 * 
 * <div class='dialog'>
 *		<div class="dialogTitle">
 *			heading label text...
 *		</div>
 *		<div class="dialogContent">
 *		</div>
 * </div>
 *
 * Note that this module must be used with appropriate CSS class definitions
 * to display correctly. NOTE: To show correctly, expect dialog & dialogContent 
 * to have a 2px border.  The following are examples:
 * 
 
TODO: copy css and a dialog drawing into here....

HTML

TODO: copy html into here....


Settings Object may contain:

	id		: css id for dialog (allows for multiple instances)
	className : css class (overrides default)
	width	: dialog box width
	height	: dialog box height (content may require a scrollbar)
	title	: dialog title text (HTML)
	buttons : Button bar definition (see below)
	content : Content definition (see below)


Content may be text or an array e.g.

	content: [
		{
			type: 'integer',
			name: 'int1',
			label: 'Debug level:',
			value: 0,
			range: {min: 0, max:10}
		},
		{
			type: 'integer',
			label: 'Display hours:',
			value: 3,
			range: {min: 2, max:6}
		},
		{
			type: 'text',
			label: 'Stuff:',
			value: 'a value',
		},
		{
			type: 'select',
			label: 'Theme:',
			value: 'black',
			range: ['black', 'blue', 'blue-flat'],
		},
		{
			type: 'checkbox',
			label: 'Profiling:',
			value: 0,
		},
		{
			type: 'buttons',
			value: 	[
				{
					type: 'ok',
					callback: function() {alert('Called embedded ok')}
				},
				{
					type: 'cancel',
					callback: function() {alert('Called embedded cancel')}
				}
			]
			
		}
	]

Valid types are:

	'text'		general text entry
	'integer'	text entry specifically for integer values
	'select'	for a drop-down list
	
	'checkbox'	a single checkbox
	'radio'

buttons may be embedded inside the content (distinct from thos displayed in the buttonbar) by specifying the type of 'buttons' and the value
is then a list of button definitions (see below).


Button bar contents are set using the settings['buttons'] field:

	buttons: [
		{
			label: 'A OK',
			type: 'ok',
			callback: function() {alert('Called ok')}
		},
		{
			label: 'Bugger',
			type: 'cancel,
			callback: function() {alert('Called cancel')}
		}
	]

 *
 */
function Dialog(settings) {  // The constructor function for the Dialog class
	this.dom = {} ;
	this.vars = {} ;
	
	// NOTE: This changes the settings parameter passed in!
	if (!settings) settings = {} ;
	this.settings = settings ;

	// Create window
    var dialog = document.createElement("div"); // create div for content
    dialog.style.visibility = "hidden";     // starts off hidden

    dialog.className = "dialog";     // so we can style it
    this.id = "dialog1";     // so we can style it
    if (this.settings.className) dialog.className = this.settings.className ; 
    if (this.settings.id) 
    {
    	dialog.id = this.settings.id ; 
    	this.id = this.settings.id ; 
    }
    dialog.style.zIndex = 100;     // top of the heap
    this.dom['dialog'] = dialog ;
    
    if (settings.width) dialog.style.width = settings.width+'px' ;
    if (settings.height) dialog.style.height = settings.height+'px' ;
    
    // Create a contained div for the optional title if required
    if (this.settings.title)
    {
	    var title = document.createElement("div");
	    dialog.appendChild(title) ;
	    title.className = "head";     // so we can style it
	    title.innerHTML = this.settings.title ;
	    this.dom['title'] = title ;
    }

    // Always create a div for the content
    var content = document.createElement("div");
    dialog.appendChild(content) ;
    content.className = "cont";     // so we can style it
    this.dom['content'] = content ;

    // Create optional button bar
    if (this.settings.buttons)
    {
	    this.dom['buttonbar'] = this._buttons(dialog, this.settings.buttons) ;
    }

	// Main content
	if (typeof this.settings.content == "string")
	{
    	content.innerHTML = this.settings.content;             // Set the text of the dialog.
    }
    else
    {
    	// Create dialog
	    this._content(content, this.settings.content) ;
    }

	// set position
	this.setxy() ;
}

//-------------------------------------------------------------------------------------------
//display the dialog centrally in the viewable area
Dialog.prototype.showCentral = function() 
{
	// Display it
	this.show() ;
	
	// Set the position.
	var viewableDims = Geometry.viewableArea() ;
	var dialog = this.dom['dialog'] ;
	
	var dialogWidth = $(dialog).width() ;
	var dialogHeight = $(dialog).height() ;
	if (dialogWidth <= 0) dialogWidth=400 ;
	if (dialogHeight <= 0) dialogHeight=400 ;
	
	var x = parseInt((viewableDims.width - dialogWidth) / 2, 10) + viewableDims.topLeft.x ;
	var y = parseInt((viewableDims.height - dialogHeight) / 2, 10) + viewableDims.topLeft.y ;
	this.setxy(x, y) ;
}



//-------------------------------------------------------------------------------------------
// display the dialog (optionally re-position)
Dialog.prototype.show = function(x, y) 
{
	var dialog = this.dom['dialog'] ;
	dialog.style.visibility = "visible"; // Make it visible.
    
    // Add the dialog to the document if it has not been added before
    if (dialog.parentNode != document.body)
        document.body.appendChild(dialog);

	this.setxy(x, y) ;
        
}

//-------------------------------------------------------------------------------------------
// Hide the dialog
Dialog.prototype.hide = function() {

    this.dom['dialog'].style.visibility = "hidden";  // Make it invisible.

    // Remove the dialog from the document if it has been added before
    if (this.dom['dialog'].parentNode == document.body)
	    document.body.removeChild(this.dom['dialog']);
}

//-------------------------------------------------------------------------------------------
// Set the content and position of the dialog
Dialog.prototype.setxy = function(x, y) 
{
	if (typeof x != "undefined")
	{
		this.settings.x = x ;
	}
	if (typeof y != "undefined")
	{
		this.settings.y = y ;
	}
	
	// Set the position.
	if (typeof this.settings.x != "undefined")
	{
	    this.dom['dialog'].style.left = this.settings.x + "px";        
	}
	if (typeof this.settings.y != "undefined")
	{
	    this.dom['dialog'].style.top = this.settings.y + "px";
	}
}

//-------------------------------------------------------------------------------------------
//Change the title
Dialog.prototype.setTitle = function(title) 
{
	if (this.dom['title'] && title)
	{
	    this.dom['title'].innerHTML = title ;
	}
}

//-------------------------------------------------------------------------------------------
//Change the contents
Dialog.prototype.setContent = function(content) 
{
	// Main content
	this.dom["content"].innerHTML = "" ;
	if (typeof content == "string")
	{
    	this.dom["content"].innerHTML = content;             // Set the text of the dialog.
    }
    else
    {
    	// Create dialog
	    this._content(this.dom["content"], content) ;
    }
}

//-------------------------------------------------------------------------------------------
// Change the Dialog css id
Dialog.prototype.setId = function(id) 
{
	this.dom['dialog'].id = id ;
}

//-------------------------------------------------------------------------------------------
// Private
//-------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------
/*
Create a "buttonbar" div

	[
		{
			label: 'A OK',
			type: 'ok',
			callback: function() {alert('Called ok')}
		},
		{
			label: 'Bugger',
			type: 'cancel,
			callback: function() {alert('Called cancel')}
		}
	]
*/
Dialog.prototype._buttons = function(node, buttons) 
{
	//NOTE: I'm having to use a table row so that the table will be centered in the div
	//      -AND- keep the buttons spaced ("floated") correctly
	// create container
    var buttonbar = document.createElement("div");
    buttonbar.className = "buttonbar"; 
    node.appendChild(buttonbar) ;
	    
	// create container that will be centered
    var table = document.createElement("table");
    table.className = "centre"; 
    buttonbar.appendChild(table) ;

    var tr = document.createElement("tr");
    table.appendChild(tr) ;
    
	// process array of configuration
	for (var i=0; i < buttons.length; i++)
	{
		var button_def = buttons[i] ;

		// Special handling for the likes of IE! Seems to sometimes say the array length is 2 when 
		// it's really only 1 !
		if (!button_def) continue ;

		
	    var td = document.createElement("td");
	    tr.appendChild(td) ;
	    var a = document.createElement("a");
		td.appendChild(a) ;
		
	    a.className = "button";
		a.setAttribute("href", '#') ; 
    	$(a).click( this._create_callback(button_def['type'], button_def['callback']) ) ;

	    var label = button_def['label'] ;
	    if (!label) label = button_def['type'] ;
	    a.appendChild(document.createTextNode(label)) ;
		
	}

	return buttonbar ;
}



//-------------------------------------------------------------------------------------------
/*
	[
		{
			type: 'integer',
			name: 'int1',
			label: 'Debug level:',
			value: 0,
			range: {min: 0, max:10}
		},
		{
			type: 'integer',
			label: 'Display hours:',
			value: 3,
			range: {min: 2, max:6}
		},
		{
			type: 'select',
			label: 'Theme:',
			value: 'black',
			range: ['black', 'blue', 'blue-flat'],
		},
		{
			type: 'checkbox',
			label: 'Profiling:',
			value: 0,
		},
		{
			type: 'buttons',
			value: 	[
				{
					type: 'ok',
					callback: function() {alert('Called embedded ok')}
				},
				{
					type: 'cancel,
					callback: function() {alert('Called embedded cancel')}
				}
			]
			
		}
	]
*/
Dialog.prototype._content = function(node, content) 
{

	// remove existing
	while( node.hasChildNodes() ) 
	{ 
		node.removeChild( node.lastChild ); 
	}

	// clear out vars
	this.vars = {} ;

	// process settings
	for (var i=0; i < content.length; i++)
	{
		var control_def = content[i] ;
		if (typeof control_def == "string")
		{
		    var div = document.createElement("div");
		    div.className = "row text";
		    div.appendChild(document.createTextNode(control_def)) ;
			node.appendChild(div) ;
	    }
	    else
	    {
			if (control_def['type'] == 'buttons')
			{
				var buttonbar = this._buttons(node, control_def['value']) ;
				buttonbar.className += " row" ;
			}
			else
			{
			    var div = document.createElement("div");
			    div.className = "row";
				node.appendChild(div) ;

				var name = control_def['name'] ;
				var label = control_def['label'] ;
				if (label)
				{
				    var label_div = document.createElement("div");
				    label_div.className = "label";
					div.appendChild(label_div) ;
				    label_div.appendChild(document.createTextNode(label)) ;
				}

				var type = control_def['type'] ;
				if (!name) name = label ;
				if (!name)
				{
					// find an unused name
					var i=0 ;
					name=type+"-"+i ;
					while (this.vars[name])
					{
						++i ;
						name=type+"-"+i ;
					}
				}
				
				if (type == 'text')
				{
				    var inp = document.createElement("input");
					inp.setAttribute("type", 'text') ;	// NOTE: IE does NOT allow this after input is added to DOM, so postpone appendChild!
					var value = control_def['value'] ; 
					if (value !== null) inp.setAttribute("value", control_def['value']) ; 
					inp.id = this.id + name ;
					div.appendChild(inp) ;
					
					// create variable to hold the control's value
					this.vars[name] = {
						"default" : value,
						"value"   : value,
						"node"    : inp
					} ;
					
				}
				else if (control_def['type'] == 'integer')
				{
		// todo....
				}
				else if (control_def['type'] == 'checkbox')
				{
		// todo....
				}
				else if (control_def['type'] == 'select')
				{
		// todo....
				}
				
				else
				{
					//error..
				}
			}
	    }
	}
}

//-------------------------------------------------------------------------------------------
// Attach callback
Dialog.prototype._create_callback = function(type, callback) 
{
	var dialog_obj = this ;
	
	if (!callback)
	{
		callback = function() {
			// ok to close
			return true ;
		} ;
	}
	
	var func ;
	if (type == "ok")
	{
    	func = function() {
    		dialog_obj._handle_ok(); 
    		if (callback( dialog_obj.vars )) 
    			dialog_obj.hide(); 
    	} ;
	}
	else
	{
    	func = function() {
    		dialog_obj._handle_cancel(); 
    		if (callback()) 
    			dialog_obj.hide(); 
    	} ;
	}
	
	return func ;
}

//-------------------------------------------------------------------------------------------
// Private callback
//-------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------
// called by OK
Dialog.prototype._handle_ok = function() 
{
	// process the variables to get their values
	for (var varname in this.vars)
	{
		var inp = this.vars[varname].node ;
		this.vars[varname].value = inp.value ;
	//	if (this.vars[varname].value === null)
	//	{
	//		this.vars[varname].value = this.vars[varname].default || 0 ;
	//	}
		
	}
}

//-------------------------------------------------------------------------------------------
// called by CANCEL
Dialog.prototype._handle_cancel = function() 
{
//alert("cancel button") ;
}
