/*
Manages a list of TV program related "things", displaying them as a tabular list. Optionally each row
can have a sub-row (e.g. a recording main row can have a number of sub-rows that are the scheduled
programs for this recording request).

NOTE: The list of "things" is stored in a SortedObjList(). Expects any "subthings" to also be stored in 
 	  a SortedObjList() (or anything that provides the values() method)
 	  
Builds the contents into the normal "gridbox" div 

*/

//========================================================================================================
// CLASS
//========================================================================================================

TvList.settings = {} ;
TvList.popup = new Popup();

TvList.IMAGE_MAP = {
	'show'	: 'plus',	
	'hide'	: 'minus'	
} ;


/*------------------------------------------------------------------------------------------------------*/
// Constructor
function TvList(args)
{
	// Data - override with args
	this.rowClass = "" ;
	this.subrowClass = "" ;
	this.index = "pid" ;
	this.subindex = "" ;					// name of field containg list of sub-things
	this.sort = TvList.sort ;
	
	this.popupClassName = "tvListPop" ;		// added to popupDiv for setting record level
	this.recselCallback = TvList.setRecordings ;	// callback called when record level changed
	this.priCallback = TvList.setRecordings ;	// callback called when priority changed
	
	// add a ref to the global settings
	this.settings = TvList.settings ;
	this.popup = TvList.popup ;
	
	// override with settings
	if (args && (typeof args == "object"))
	{
		for (var setting in args)
		{
			this[setting] = args[setting] ;
		}
	}
	
	
	//--------------------------------------------------------------------
	// Cache
	//?????
	
	//--------------------------------------------------------------------
	// Init code
	
	// list of "things"
	this.list = new SortedObjList(this.index, this.sort ) ;

	this.init(
		this.index, 
		this.sort
	) ;
	
}

// Sort programs such that the newest program appears first
TvList.sort = function(a,b) {
	// NOTE: Invert compare to sort "descending"
	var cmp = Prog.prog_sort(a, b) ;
	cmp = -cmp ;
	return cmp;
} 



/*------------------------------------------------------------------------------------------------------*/
// Set the the class settings
//
//
TvList.setup = function(settings)
{
	// Init the common display settings - anything else is added by the derived object
	for (var setting in settings)
	{
		TvList.settings[setting] = settings[setting] ;
	}
	
	TvList.settings.TOTAL_PAD = 10 ;
	if (Env.BROWSER.PS3)
	{

// log.debug(" + set width for PS3") ;

		// For PS3 - fill the screen
		TvList.settings.GRID_WIDTH = Env.SCREEN_WIDTH-TvList.settings.TOTAL_PAD ;
	}
	else
	{
// log.debug(" + set 90% width") ;

		// For everything else, use 98%
		TvList.settings.GRID_WIDTH = parseInt(Env.SCREEN_WIDTH * 0.98) ;
	}
	TvList.settings.GRID_HEIGHT = Env.SCREEN_HEIGHT ;
	
	TvList.settings.TOTAL_WIDTH = TvList.settings.GRID_WIDTH + TvList.settings.TOTAL_PAD ;
	TvList.settings.TOTAL_PX = TvList.settings.TOTAL_WIDTH ;

	// First column of the list is ALWAYS an index
	TvList.settings.IDX_PX = 50 ;
	TvList.settings.HIDE_PX = 50 ;
	TvList.settings.PRI_PX = 50 ;
	TvList.settings.REC_PX = 50 ;
	TvList.settings.DIR_PX = 50 ;
//	TvList.settings.DATE_PX = 150 ;
	TvList.settings.DATE_PX = 250 ;
//	TvList.settings.TIME_PX = 150 ;
	TvList.settings.TIME_PX = 250 ;
	TvList.settings.CHAN_PX = 150 ;

	// Popup size
	TvList.settings.POPUP_WIDTH_PX = 300 ;

	// Font - TODO - calc based on browser, screen size etc
	TvList.settings.FONT_SIZE = 21 ;
}

/*------------------------------------------------------------------------------------------------------*/
//Change record level
//TvList.setRecordings = function(record, pid, rid, priority)
TvList.setRecordings = function(prog)
{
	// Setup object with real callback
//	TvList.settings.app.setRecordings(record, pid, rid, priority) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Create a handler that will show/hide all entrys' sub-entries
TvList.global_show_handler = function(tvListObj, showHide) 
{
	var image = {
			'hide': tvListObj.settings.app.ImageCache[TvList.IMAGE_MAP['hide']].src,	
			'show': tvListObj.settings.app.ImageCache[TvList.IMAGE_MAP['show']].src	
		} ;
	var imageToggle = {
		'hide': image.show,	
		'show': image.hide	
	} ;
	
//	<div class=".. entall">
//		<ol>
//			<li class="showHide hide">
//				<a><img src="minus.png">
	
	return function() {
		
		// Reset all images
//		$('.entall')
//			.find('.showHide img').attr('src', imageToggle[showHide])
//			.toggleClass('hide', showHide == 'hide') ;
		var showHide$ = $('.entall .showHide')
			.toggleClass('hide', showHide == 'show') ;
		$('img', showHide$)
			.attr('src', imageToggle[showHide]) ;
			
		// show/hide all sub-entries
		$('.suball')[showHide]() ;
		
	} ;
}



//========================================================================================================
// INSTANCE
//========================================================================================================

/*------------------------------------------------------------------------------------------------------*/
//Initialise list
//
TvList.prototype.init = function(index, sort_fn)
{
	// HOOK
}

/*------------------------------------------------------------------------------------------------------*/
// Add/Create progs
//
// Array of thing "HASHes"
//
TvList.prototype.update = function(data)
{
	Profile.start('TvList.update') ;

	// Remove existing
	this.list.empty() ;
	
	// Create list of objects
	for (var i=0; i < data.length; ++i)	{
		// create a new thing entry based on the data received
		var thing = this.createEntry(data[i]) ;
		
		// Add it to the list
		this.list.add(thing) ;
	}

	Profile.stop('TvList.update') ;
}




/*------------------------------------------------------------------------------------------------------*/
// Clear out the gridbox
TvList.prototype.clear_grid = function()
{
	var gridbox = document.getElementById("gridbox");
	gridbox.innerHTML = "" ;
}


//===[ Record Selector ]==================================================================================

/*------------------------------------------------------------------------------------------------------*/
TvList.prototype.popup_recsel_contents = function(popupDiv, record_select, progObj)
{
	popupDiv.className = this.popupClassName ;

	var recUl = document.createElement("ul");
	recUl.className = "recprog" ;
	
		var recLi = document.createElement("li");
		recLi.className = "sub" ;
		recUl.appendChild(recLi) ;
	
			// Add list of record options (with handler for each)
			Prog.create_recSelTabs(recLi, progObj, record_select) ;
	
	
	popupDiv.appendChild(recUl) ;
}



/*------------------------------------------------------------------------------------------------------*/
// Add a popup window for recording selection on multiple lines of the TvList display. 
//
TvList.prototype.add_record_popup = function(node, progobj)
{
	var thisObj = this ;
	
	// use this width
	var popup_width = thisObj.settings.POPUP_WIDTH_PX ;
	
	var progSettings = {
		//-----------------------------------------------------
		create_popup: function(settings, x, y, callback) {
			
			var popupDiv = document.createElement("div");
			thisObj.popup_recsel_contents(popupDiv, callback, progobj) ; 
			var popupObj = {
				dom 	: popupDiv
			} ;
			
			return popupObj ;
		},
		//-----------------------------------------------------
		popup_node	: function(settings, popupObj) {
			return popupObj.dom ;
		},
		//-----------------------------------------------------
		show_popup	: function(settings, popupObj, x, y) {
			
			var popupDiv = popupObj.dom ;
			
			// ensure we're over the popupDiv to stop the popup cycling up/down
			x = x - 10 ;
			y = y - 10 ;
			
			// Show the popup window
			thisObj.popup.show(popupDiv, x, y, popup_width);
			thisObj.popup.adjustXY(x, y) ;
		},
		//-----------------------------------------------------
		hide_popup	: function(settings, popupObj) {
			thisObj.popup.hide();
		},
		//-----------------------------------------------------
		callback	: function(settings, vars) {
			
			var progObject = vars.prog ;
			var new_rec = vars.val ;
			
			// only update if changed
			if (new_rec != progObject.record)
			{
				// Call the GridApp.set_rec() method
				var old_rec = progObject.record ;
				progObject.record = new_rec ;
				thisObj.recselCallback(progObject, old_rec) ;
				
			}

		}
	} ;
	
	PopupHandler.add_popup(node, progSettings) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add a record level selection element
TvList.prototype.display_recsel = function(ol, prog)
{
	var li ;

	li = document.createElement("li");
	li.className = "lcol" ;
	li.style.width = this.settings.REC_PX+'px' ;
	ol.appendChild(li) ;

		var a = document.createElement("a");
		li.appendChild(a) ;
	
			var img = document.createElement("img");
			img.src = Prog.RecImg(prog.record) ; 
			a.appendChild(img) ;

			// add a popup display to show program details
			this.add_record_popup(a, prog) ;
			
	return li ;
}


//===[ Priority Selector ]================================================================================

/*------------------------------------------------------------------------------------------------------*/
TvList.prototype.popup_prisel_contents = function(popupDiv, popup_callback, progObj)
{
	popupDiv.className = this.popupClassName ;

	var ul = document.createElement("ul");
	
	// Add list of record options (with handler for each)
//	Prog.create_priSelList(ul, progObj, progObj.record, popup_callback) ;
	Prog.create_priSelList(ul, progObj, popup_callback) ;

	popupDiv.appendChild(ul) ;
}



/*------------------------------------------------------------------------------------------------------*/
//Add a popup window for priority selection on multiple lines of the TvList display. 
//
TvList.prototype.add_priority_popup = function(node, progobj)
{
	var thisObj = this ;
	
	// use this width
	var popup_width = thisObj.settings.POPUP_WIDTH_PX ;
	
	var progSettings = {
		//-----------------------------------------------------
		create_popup: function(settings, x, y, popup_callback) {
			
			var popupDiv = document.createElement("div");
			thisObj.popup_prisel_contents(popupDiv, popup_callback, progobj) ; 
			var popupObj = {
				dom 	: popupDiv
			} ;
			
			return popupObj ;
		},
		//-----------------------------------------------------
		popup_node	: function(settings, popupObj) {
			return popupObj.dom ;
		},
		//-----------------------------------------------------
		show_popup	: function(settings, popupObj, x, y) {
			
			var popupDiv = popupObj.dom ;
			
			// ensure we're over the popupDiv to stop the popup cycling up/down
			x = x - 10 ;
			y = y - 10 ;
			
			// Show the popup window
			thisObj.popup.show(popupDiv, x, y, popup_width);
			thisObj.popup.adjustXY(x, y) ;
		},
		//-----------------------------------------------------
		hide_popup	: function(settings, popupObj) {
			thisObj.popup.hide();
		},
		//-----------------------------------------------------
		callback	: function(settings, vars) {
			
			var progObject = vars.prog ;
			var new_pri = vars.val ;
			
			// only update if changed
			if (new_pri != progObject.priority)
			{
				// Call the GridApp.set_rec() method
				progObject.priority = new_pri ;
//				thisObj.recselCallback(progObject.record, progObject.pid, progObject.rid, progObject.priority) ;
				thisObj.recselCallback(progObject, progObject.record) ;
			}

		}
	} ;
	
	PopupHandler.add_popup(node, progSettings) ;
}



/*------------------------------------------------------------------------------------------------------*/
//Add a record level selection element
TvList.prototype.display_prisel = function(ol, prog)
{
	var li ;

	var pri = Prog.priIndex(prog.priority) ;
	
	li = document.createElement("li");
	li.className = "lcol" ;
	li.style.width = this.settings.REC_PX+'px' ;
	ol.appendChild(li) ;

		var a = document.createElement("a");
		li.appendChild(a) ;
	
			var img = document.createElement("img");
			img.src = Prog.PriImg(pri) ; 
			a.appendChild(img) ;

			// add a popup display to show program details
			this.add_priority_popup(a, prog) ;
			
	return li ;
}


//===[ Path Selector ]====================================================================================

/*------------------------------------------------------------------------------------------------------*/
TvList.prototype.popup_dirsel_contents = function(popupDiv, popup_callback, progObj)
{
	popupDiv.className = this.popupClassName ;

//	var div = document.createElement("div");
	
	//----------------------------------------------------------------------------
	// Value change callback
	function add_editor_fn(progObj, callback) {
		
		return function(edit) {
			
			//----------------------------------------------------------------------------
			// Value change callback
			function dir_change(progObject, newVal) {
				
				// only update if changed
				if (newVal != progObject.pathspec)
				{
					callback({
				   		prog : progObject, 
				   		val  : newVal 
			   		}) ;
				}
			}
			
			// Create the text edit
			$(edit).change(function() {
				dir_change(progObj, edit.value);
			})
		} ;
	}

	// Add directory editor
	this.display_edit(popupDiv, 300, progObj.pathspec, add_editor_fn(progObj, popup_callback), "")

//	popupDiv.appendChild(div) ;
}



/*------------------------------------------------------------------------------------------------------*/
//Add a popup window for pathspec selection on multiple lines of the TvList display. 
//
TvList.prototype.add_dir_popup = function(node, progobj)
{
	var thisObj = this ;
	
	// use this width
	var popup_width = thisObj.settings.POPUP_WIDTH_PX ;
	
	var progSettings = {
		//-----------------------------------------------------
		create_popup: function(settings, x, y, popup_callback) {
			
			var popupDiv = document.createElement("div");
			thisObj.popup_dirsel_contents(popupDiv, popup_callback, progobj) ; 
			var popupObj = {
				dom 	: popupDiv
			} ;
			
			return popupObj ;
		},
		//-----------------------------------------------------
		popup_node	: function(settings, popupObj) {
			return popupObj.dom ;
		},
		//-----------------------------------------------------
		show_popup	: function(settings, popupObj, x, y) {
			
			var popupDiv = popupObj.dom ;
			
			x = x+10 ;
			y = y ;
			
			// Show the popup window
			thisObj.popup.show(popupDiv, x, y, popup_width);
			thisObj.popup.adjustXY(x, y) ;
		},
		//-----------------------------------------------------
		hide_popup	: function(settings, popupObj) {
			thisObj.popup.hide();
		},
		//-----------------------------------------------------
		callback	: function(settings, vars) {
			
			var progObject = vars.prog ;
			var new_dir = vars.val ;
			
			// only update if changed
			if (new_dir != progObject.pathspec)
			{
				// Call the GridApp.set_rec() method
				progObject.pathspec = new_dir ;
				thisObj.recselCallback(progObject, progObject.record) ;
			}

		}
	} ;
	
	PopupHandler.add_popup(node, progSettings) ;
}



/*------------------------------------------------------------------------------------------------------*/
//Add a record level selection element
TvList.prototype.display_dirsel = function(ol, prog)
{
	var pathspec = '' ;
	if (prog.hasOwnProperty('pathspec'))
	{
		pathspec = prog.pathspec ;
	}
	

	var li = document.createElement("li");
	$(li)
		.addClass("lcol")
		.width(this.settings.DIR_PX)
		.appendTo($(ol))
			.append(
				$('<a>')
				.addClass('dirSel')
				.append(
					$('<img>')
					.attr({
						'src'	: Prog.ImageCache['icon_dir'].src,
						'title'	: 'Dir: ' + pathspec
					})
				)
//				.click()
			) ;
				
	// add a popup display to show program details
	this.add_dir_popup($('.dirSel', $(li)).get(0), prog) ;
	
	return li ;
}



/*------------------------------------------------------------------------------------------------------*/
//Add a text edit
TvList.prototype.display_edit = function(ol, width, text, add_editor_fn, className)
{
	var margin=10 ;
	
	// Container
	var li = this._display_li(ol, width, className) ;
	
	// Edit - slightly smaller than container
	var edit = document.createElement("input");
	edit.className = "edView" ;
	edit.style.width = (width-2*margin)+'px' ;
	edit.style.marginLeft = margin+'px' ;

	edit.setAttribute("type", 'text') ;	// NOTE: IE does NOT allow this after input is added to DOM, so postpone appendChild!
	if (text !== null) edit.setAttribute("value", text) ; 
	
	li.appendChild(edit) ;
	add_editor_fn(edit) ;

}



/*------------------------------------------------------------------------------------------------------*/
//Add a text element
TvList.prototype.display_labelled_edit = function(ol, labelWidth, label, width, text, add_editor_fn, className)
{
	// Label
	this.display_label(ol, labelWidth, label, 'edLabel') ;
//	this.display_inplace_edit(ol, width, text, add_editor_fn, className);
	this.display_edit(ol, width, text, add_editor_fn, className);
}

/*------------------------------------------------------------------------------------------------------*/
//Add a combobox element
TvList.prototype.display_selector = function(ol, width, value, valuesArray, namesArray, className, changeHandler)
{
	var margin=10 ;
	
	// Container
	var li = this._display_li(ol, width, className) ;
	
	// View - slightly smaller than container
	var view = document.createElement("li");
	view.className = "selector" ;
	var selWidth = (width-2*margin) ;
	view.style.width = selWidth+'px' ;
	view.style.marginLeft = margin+'px' ;
	
		var select = document.createElement("select");
		select.style.width = selWidth+'px' ;
		var html = "" ;
		
		value = value.toLowerCase() ;
		for (var i=0, len=valuesArray.length; i<len; i++)
		{
//			var option = document.createElement("option");
//			if (value == valuesArray[i].toLowerCase())
//				option.setAttribute('selected', 'selected') ; 
//			option.appendChild(document.createTextNode(valuesArray[i])) ;
//			select.appendChild(option) ;
			
			html += '<option ' ;
			if (value == valuesArray[i].toLowerCase())
			{
				html += 'selected="" ' ;
			}
			html += 'value="' + valuesArray[i] + '">' + namesArray[i] + '</option>' + "\n" ;
			
		}
		select.innerHTML = html ;
		
		
		if (changeHandler)
		{
log.debug("Added selector change handler for "+value);			
			select.changeHandler = changeHandler ;
			$(select).change(changeHandler) ;
		}

	view.appendChild(select) ;
	
	li.appendChild(view) ;
	
	return select ;
}



/*------------------------------------------------------------------------------------------------------*/
// Labelled selector - returns the select DOM node
TvList.prototype.display_labelled_select = function(ol, labelWidth, label, width, value, valuesArray, namesArray, className, changeHandler)
{
	// Label
	this.display_label(ol, labelWidth, label, 'edLabel') ;
	var select = this.display_selector(ol, width, value, valuesArray, namesArray, className, changeHandler);
	
	return select ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add a text element
TvList.prototype._display_li = function(ol, width, className)
{
	var li ;

	li = document.createElement("li");
	
	var cname = "lcol" ;
	if (className)
	{
		cname = cname + ' ' + className ;
	}
	li.className = cname ;
	
	li.style.width = width+'px' ;
	li.style.overflow = 'hidden' ;
	ol.appendChild(li) ;
	
	return li ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add a control to show/hide sub rows
//
// <div class="lrow entX entall">
// 	 <ol>
// 		<li class="lcol showHide">
//         +/-
//	    <li class="lcol">
//         [first column..]
//
TvList.prototype.display_showHide = function(parentNode, ol, idx)
{
	var tvListObj = this ;
	var image = {
		'hide': tvListObj.settings.app.ImageCache[TvList.IMAGE_MAP['hide']].src,	
		'show': tvListObj.settings.app.ImageCache[TvList.IMAGE_MAP['show']].src	
	} ;
	var imageToggle = {
		'hide': image.show,	
		'show': image.hide	
	} ;
	
	var li = $('<li>')
				.width(tvListObj.settings.HIDE_PX)
				.addClass("showHide")
				.addClass("hide")
				.append(
					$('<a>')
					.attr('title', 'Click to show/hide')
					.append(
						$('<img>')
						.attr('src', image.hide)
						.css( {id : 'imgId'+idx} )
					)
				)
				.click(function(event){
					
					var div$ = $(this) ;
					
					var newState = 'show' ;
					if (div$.hasClass('hide'))
					{
						newState = 'hide' ;
					}

					// Toggle sub-entries
//					$('.sub' + idx).toggle() ;
					$('.sub' + idx)[newState]() ;
					
					// Switch image
//					div$.find('img').attr('src', imageToggle[newState]) ;
					$('img', div$).attr('src', imageToggle[newState]) ;

					// toggle class setting
					div$.toggleClass('hide', newState == 'show') ;
					
		        })
				.appendTo(ol)
				.get(0) ;
	
	return li ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add a blank element
//
TvList.prototype.display_empty = function(ol, width, className)
{
	var li = this._display_li(ol, width, className) ;
	return li ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add a blank show/hide element
//
TvList.prototype.display_emptyShowHide = function(parentNode, ol, idx)
{
	var li = this.display_empty(ol, this.settings.HIDE_PX, "showHide") ;
	return li ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add a text element
TvList.prototype.display_text = function(ol, width, text, className)
{
	var li ;

	li = this._display_li(ol, width, className) ;
	
	li.appendChild(document.createTextNode(text)) ;
	
	return li ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add a label element
TvList.prototype.display_label = function(ol, width, text, className)
{
	var li = this.display_text(ol, width, text, className) ;
	li.style.textAlign="right" ;
	
	return li ;
}


/*------------------------------------------------------------------------------------------------------*/
//Add an index element
TvList.prototype.display_index = function(ol, idx)
{
	return this.display_text(ol, this.settings.IDX_PX, idx, "lidx") ;
}


/*------------------------------------------------------------------------------------------------------*/
//Add a channel name element
TvList.prototype.display_chan = function(ol, chan)
{
	return this.display_text(ol, this.settings.CHAN_PX, chan, "lchan") ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add start & end time
TvList.prototype.display_startend = function(ol, start_time, end_time)
{
	var text = start_time+' - '+end_time
	return this.display_text(ol, this.settings.TIME_PX, text) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add date
TvList.prototype.display_date = function(ol, date)
{
	var dt = DateUtils.date2dt(date) ;
	var datestr = DateUtils.dt2string(dt) ;
	return this.display_text(ol, this.settings.DATE_PX, datestr) ;
}



/*------------------------------------------------------------------------------------------------------*/
// Create the first column of a sub-entry row - needs to be offset by the index column width
TvList.prototype.subentry_firstcol = function(node)
{
	node.style.marginLeft = TvList.settings.HIDE_PX+'px' ;
}




/*------------------------------------------------------------------------------------------------------*/
//Display a sub list under the main entry row
TvList.prototype._display_subentry = function(parent_idx, idx, subthing)
{
	var rowDiv = document.createElement("div");
	
	var cname = "lrow" ;
	cname = cname + ' ' + "sub"+parent_idx + ' ' + 'suball' ;
	if (this.subrowClass)
	{
		cname = cname + ' ' + this.subrowClass ;
	}
	rowDiv.className = cname ;

		var ol = document.createElement("ol");
		rowDiv.appendChild(ol) ;
		
		this.display_subentry(idx, subthing, ol) ;
		
	return rowDiv ;
}


/*------------------------------------------------------------------------------------------------------*/
//Display a list entry - an amended Recording
TvList.prototype._display_entry = function(idx, thing)
{
	//	<div class="lrow">
	//		<ol>
	//			<li class="lcol" style="width: 200px;">
	//				Wed 21 June
	//			</li>
	//		
	//			<li class="lcol" style="width: 200px;">
	//				12:00 - 13:00
	//			</li>
	//		
	//			<li class="lcol lchan" style="width: 300px;">
	//				Channel 4
	//			</li>
	//		
	//			<li class="lcol" style="width: 400px;">
	//				Homes Under the Hammer
	//			</li>
	//		
	//			<li class="lcol" style="width: 30px;">
	//				<a href="#"><img src="record-multi"></a>
	//			</li>
	//		
	//		</ol>
	//	
	//	</div>
	//
	var rowDiv = document.createElement("div");
	var cname = "lrow" ;
	cname = cname + ' ' + "ent"+idx + ' ' + 'entall' ;
	if (this.entry_inactive(thing))
	{
		cname = cname + " linactive" ;
	}
	if (this.rowClass)
	{
		cname = cname + ' ' + this.rowClass ;
	}
	rowDiv.className = cname ;
	rowDiv.className = cname ;

		var ol = document.createElement("ol");
		rowDiv.appendChild(ol) ;
		
			// show/hide is always the first col
			if (this.entry_inactive(thing))
			{
				this.display_emptyShowHide(rowDiv, ol, idx) ;
			}
			else
			{
				this.display_showHide(rowDiv, ol, idx) ;
			}
			
			// do rest
			this.display_entry(idx, thing, ol) ;
			
			
	return rowDiv ;
}

/*------------------------------------------------------------------------------------------------------*/
// Display the list
TvList.prototype.display = function()
{
	// set body width
	var body = document.getElementById("quartz-net-com");
    body.style.fontSize = (TvList.settings.FONT_SIZE) + "px" ;
    body.style.fontFamily = "arial,helvetica,clean,sans-serif" ;
    
	var qbody = document.getElementById("quartz-body");
	var body_pad = 100 ;
	qbody.style.width = (TvList.settings.TOTAL_PX+body_pad)+"px" ; 
	var qcontent = document.getElementById("quartz-content");
	qcontent.style.width = (TvList.settings.TOTAL_PX+body_pad)+"px" ; 

	var listDiv = document.getElementById("list-body");
	var prev_gridbox = document.getElementById("gridbox");
	
	// Change heading
	this.display_head() ;
	
	// New display
	var gridbox = document.createElement("div");
	gridbox.className = "grid" ;
	gridbox.id = "gridbox" ;
	
	// Replace previous display with the new one
	listDiv.replaceChild(gridbox, prev_gridbox) ;
	
	var things = this.list.values() ;
	var rowDiv = this.display_start(things.length) ;
	if (rowDiv) gridbox.appendChild(rowDiv) ;
	
	// Add things
	for (var i=0; i < things.length; i++)
	{
		var thing = things[i] ;
		rowDiv = this._display_entry(i+1, thing) ;
		gridbox.appendChild(rowDiv) ;
		
		// Sub-things
		if (thing.hasOwnProperty(this.subindex))
		{
			var subthings = thing[this.subindex].values() ;
			for (var j = 0; j < subthings.length; j++)
			{
				rowDiv = this._display_subentry(i+1, j+1, subthings[j]) ;
				gridbox.appendChild(rowDiv) ;
			}
		}
	}

	rowDiv = this.display_end(things.length) ;
	if (rowDiv) gridbox.appendChild(rowDiv) ;
}

//========================================================================================================
// DERIVED OBJECTS MUST OVERRIDE
//========================================================================================================

/*------------------------------------------------------------------------------------------------------*/
//Create a thing Object based on data array
//
TvList.prototype.createEntry = function(args)
{
	// Override
	return {} ;
}


/*------------------------------------------------------------------------------------------------------*/
//Display grid heading
TvList.prototype.display_head = function()
{
	// Need to override with something like:
	// TitleBar.display_head("Program Recording List", "", null, 'TvList') ;
}

/*------------------------------------------------------------------------------------------------------*/
// Is this entry active
TvList.prototype.entry_inactive = function(entry)
{
	// OVERRIDE
	return 0 ;
}

/*------------------------------------------------------------------------------------------------------*/
//Caled before list is displayed
TvList.prototype.display_start = function(numThings)
{
	var rowDiv = 0 ;
	return rowDiv ;
}

/*------------------------------------------------------------------------------------------------------*/
//Caled after list is displayed
TvList.prototype.display_end = function(numThings)
{
	var rowDiv = 0 ;
	return rowDiv ;
}


/*------------------------------------------------------------------------------------------------------*/
//Display a list entry
TvList.prototype.display_entry = function(idx, entry, ol)
{
	// OVERRIDE
}

/*------------------------------------------------------------------------------------------------------*/
//Display a sub list under the main entry row
TvList.prototype.display_subentry = function(idx, subthing, ol)
{
	// OVERRIDE
}

/////////////////////////////////////////////////////
// Add object to prototype for ALL instances to share the same data
// Point to a copy of the same object in the "class" variable so 
// data can be accessed as TvList.globals (rather than via instance)
//
//
//TvList.prototype.globals = {} ;
//TvList.globals = TvList.prototype.globals ;
//
//var xx = new TvList() ;
//var xx2 = new TvList() ; // now xx.globals = xx2.globals = TvList.globals
//
//xx.globals["new"] = "xx" ; 
//xx2.globals["new"] = "xx2" ;
//	TvList.globals["new"] = "a string1" ;
//	TvList.globals["new"] = "a string2" ;
//	TvList.globals["new"] = "a string3" ;
//
//	// now xx.globals["new"] = xx2.globals["new"] = TvList.globals["new"]= "a string3"
