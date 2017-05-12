/*
Manages a list of results from a program search

*/

/*======================================================================================================*/
//Constructor
/*======================================================================================================*/

SearchList.settings = {} ;

// The last search object used in a search
SearchList.latestSearch = {} ;

//Create the popup object we'll use
SearchList.popup = new Popup();

// A dummy Prog to use with setting up new recordings
SearchList.srchProg = new Prog() ;

//Map search settings response
SearchList.SEARCH_MAP = {
	0	: "title", 
	1	: "desc",
	2	: "genre",
	3	: "channel",
	4	: "listingsType",
} ;

//Map from array index to entry field
SearchList.MAP = {
	0	: "date", 
	
	1	: "progs_array"
} ;

SearchList.SELECT = {} ;
SearchList.SELECT.ANY_CHAN = "-Any Channel-" ;
SearchList.SELECT.ANY_TYPE = "-Any-" ;


/*------------------------------------------------------------------------------------------------------*/
//Each entry is a date
SearchList.sort = function(a,b) {
	var cmp = DateUtils.dateCompare(a.date, b.date);
	return cmp;
} 

// Sort programs by date
SearchList.subsort = function(a,b) {
	// NOTE: Invert compare to sort "descending"
	var cmp = Prog.prog_sort(a, b) ;
	return cmp;
} 

/*------------------------------------------------------------------------------------------------------*/
//Change record level on an existing recording (found during search)
//SearchList.setRecordings = function(record, pid, rid, priority)
SearchList.setRecordings = function(prog)
{
	SearchList.settings.app.setSearchRec(prog, SearchList.latestSearch) ;
}



/*------------------------------------------------------------------------------------------------------*/
SearchList.args = {
		index 		: "date" ,
		subindex 	: "progsList" ,
		sort 		: SearchList.sort,
		rowClass 	: "",
		subrowClass : "lprog",
			
		popupClassName 	: "recListPop",
		
		// used to change an existing Prog (found in search)
		recselCallback 	: SearchList.setRecordings,
		priCallback 	: SearchList.setRecordings
			
	} ;


/*------------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------------*/
function SearchList()
{
	RecList.call(this, SearchList.args) ;
	
	// add a ref to the global settings
	this.settings = SearchList.settings ;

	for (var i in SearchList.SEARCH_MAP)
	{
		var field = SearchList.SEARCH_MAP[i] ;
		this[field] = "" ;
	}

	// filled with (dynamic) list of channels
	this.channels = [] ;

	// DOM nodes
	this.searchBar = null ;
	this.typeSelector = null ;
	this.chanSelector = null ;
	this.recList = null ;
	
	// Init the search Prog
	SearchList.srchProg.record = 0 ;
	SearchList.srchProg.priority = Prog.DEFAULT_PRIORITY ;
	this.updateProg() ;
}

SearchList.initSearch = function(searchObj)
{
	if (!searchObj || (typeof searchObj != "object"))
	{
		searchObj = {} ;
	}
	for (var i in SearchList.SEARCH_MAP)
	{
		var field = SearchList.SEARCH_MAP[i] ;
		if (!searchObj.hasOwnProperty(field))
		{
			searchObj[field] = "" ;
		}
	}

	return searchObj ;
}

SearchList.copySearch = function(searchObj, destObj)
{
	for (var i in SearchList.SEARCH_MAP)
	{
		var field = SearchList.SEARCH_MAP[i] ;
		destObj[field] = searchObj[field] ;
	}

	return destObj ;
}


//Subclass from RecList
SearchList.prototype = new RecList(SearchList.args) ;

//Remove TvList properties from prototype
for (m in SearchList.prototype)
{
	if (typeof m == 'function')
		continue ;
	
	delete SearchList.prototype[m] ;
}

//Set constructor
SearchList.prototype.constructor = SearchList ;



/*------------------------------------------------------------------------------------------------------*/
//Set the display windows
//start date & hour, display period in hours
//
//
//	DISPLAY_DATE: "2009-08-07", 
//	DISPLAY_HOUR: 12, 
//	DISPLAY_PERIOD: 3
//
//
SearchList.setup = function(settings)
{
	// Update base class
	RecList.setup(settings) ;

	// Copy settings
	for (var setting in RecList.settings)
	{
		SearchList.settings[setting] = RecList.settings[setting] ;
	}
	
	
	SearchList.settings.DATE_PX = 250 ;
	SearchList.settings.TIME_PX = 250 ;
	SearchList.settings.CHAN_PX = 150 ;
	
	// Search bar
	SearchList.settings.LABEL_TITLE_PX = 50 ;
	SearchList.settings.LABEL_DESC_PX = 120 ;
	SearchList.settings.LABEL_GENRE_PX = 70 ;

	SearchList.settings.LABEL_TYPE_PX = 70 ;
	SearchList.settings.LABEL_CHAN_PX = 90 ;
	
	SearchList.settings.EDIT_TITLE_PX = SearchList.settings.LABEL_TITLE_PX ;
	SearchList.settings.EDIT_DESC_PX = SearchList.settings.LABEL_DESC_PX ;
	SearchList.settings.EDIT_GENRE_PX = SearchList.settings.LABEL_GENRE_PX ;
	SearchList.settings.EDIT_CHAN_PX = 200 ;
	SearchList.settings.EDIT_TYPE_PX = 110 ;
	SearchList.settings.EDIT_MIN_PX = 50 ;

	SearchList.settings.END_MARGIN_PX = 10 ;
	
	
	// max length in chars
	SearchList.settings.CHAN_MAX_LEN = 16 ;
	
	SearchList.settings.SEARCH_PX = SearchList.settings.REC_PX ;
	
	// Major "items" (program headings)
	SearchList.settings.ENTRY_PAD_PX = SearchList.settings.TOTAL_PX - (
			SearchList.settings.HIDE_PX +
			SearchList.settings.DATE_PX 
		) ;
	
	SearchList.settings.TIME_PX = 250 ;

	SearchList.settings.PROG_TEXT_PX = RecList.settings.TOTAL_PX - (
			SearchList.settings.REC_PX +
			SearchList.settings.HIDE_PX +
			SearchList.settings.CHAN_PX +
			SearchList.settings.TIME_PX +
			SearchList.settings.PROG_TITLE_PX 
		) ;

}

/*------------------------------------------------------------------------------------------------------*/
//Create a new fuzzy recording - based on current search settings
SearchList.setFuzzyRecordings = function(prog)
{
	for (var i in SearchList.SEARCH_MAP)
	{
		var field = SearchList.SEARCH_MAP[i] ;
		prog[field] = SearchList.latestSearch[field] ;
	}
	
	SearchList.settings.app.setFuzzySearchRec(prog, SearchList.latestSearch) ;
}



/*======================================================================================================*/
//SPECIFIC
/*======================================================================================================*/

//Update the dummy search Prog with the current search settings
SearchList.prototype.updateProg = function()
{
	for (var i in SearchList.SEARCH_MAP)
	{
		var field = SearchList.SEARCH_MAP[i] ;
		SearchList.srchProg[field] = this[field] ;
	}
}


/*======================================================================================================*/
//OVER-RIDE
/*======================================================================================================*/

/*------------------------------------------------------------------------------------------------------*/
//Create a thing Object based on data array
//
SearchList.prototype.createEntry = function(args)
{
	// Create a mapping from name -> value
	var entry_args = [] ;
	for (var i in SearchList.MAP)
	{
		var field = SearchList.MAP[i] ;
		entry_args[field] = null ;
		if (args[i])
		{
			entry_args[field] = args[i] ;
		}
	}

	var entry = {
		date 		: entry_args["date"],
		progsList 	: new SortedObjList("pid", SearchList.subsort)
	}
	
	// Process progs list
	for (var i = 0; i < entry_args["progs_array"].length; i++)
	{
		var prog = new Prog(entry_args["progs_array"][i]) ;

		// Add to list
		entry.progsList.add(prog) ;
	}
	return entry ;
}


/*------------------------------------------------------------------------------------------------------*/
//Display grid heading
SearchList.prototype.display_head = function()
{
	TitleBar.display_head("Search Programs", "", null, 'SearchList') ;
	
	// Add some extra tools
	TitleBar.addTool(TvList.IMAGE_MAP["show"], "Show all entries", TvList.global_show_handler(this, "show")) ;
	TitleBar.addTool(TvList.IMAGE_MAP["hide"], "Hide all entries", TvList.global_show_handler(this, "hide")) ;
	
}


/*------------------------------------------------------------------------------------------------------*/
//Is this entry active
SearchList.prototype.entry_inactive = function(entry)
{
	var inactive  = 0 ;
	return inactive ;
}


/*------------------------------------------------------------------------------------------------------*/
//Display a list entry
SearchList.prototype.display_entry = function(idx, entry, ol)
{
	this.display_date(ol, entry.date) ;
	
	// Pad to the RHS of the screen
	this.display_text(ol, this.settings.ENTRY_PAD_PX, "") ;
}

/*------------------------------------------------------------------------------------------------------*/
//Display a sub list under the main entry row
SearchList.prototype.display_subentry = function(idx, prog, ol)
{
	var li = this.display_recsel(ol, prog) ;
	this.subentry_firstcol(li) ;
	
	this.display_chan(ol, SearchList.settings.app.allChans[prog.chanid].name) ;
//	this.display_date(ol, prog.start_date) ;
	this.display_startend(ol, prog.start_time, prog.end_time) ;
	this.display_text(ol, this.settings.PROG_TITLE_PX, prog.title) ;
	this.display_text(ol, this.settings.PROG_TEXT_PX, prog.description) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Caled before list is displayed
SearchList.prototype.display_start = function(numThings)
{
	var rowDiv = document.createElement("div");
	var cname = "lrow" ;
	rowDiv.className = cname ;

		var ol = document.createElement("ol");
		rowDiv.appendChild(ol) ;
		
			this.search_row(ol) ;
			
	return rowDiv ;
}

/*------------------------------------------------------------------------------------------------------*/
//Caled after list is displayed
SearchList.prototype.display_end = function(numThings)
{
	// Adjust the main search bar elements so they fit the window width
	this.sizeSearchBar() ;
	
	// don't add anything else
	var rowDiv = 0 ;
	return rowDiv ;
}


/*======================================================================================================*/
// NEW
/*======================================================================================================*/

/*------------------------------------------------------------------------------------------------------*/
// Return the current listings type value
SearchList.prototype.typeValue = function(newType)
{
	var type = this.listingsType.toLowerCase() ;
	if (newType)
	{
		type = newType.toLowerCase() ;
	}
	var anyTypes = SearchList.SELECT.ANY_TYPE.toLowerCase() ;
	if (type == anyTypes)
	{
		type = "" ;
	}
	this.listingsType = type ;
	return type ;
}

/*------------------------------------------------------------------------------------------------------*/
// Return the current channel name value
SearchList.prototype.chanValue = function(newChan)
{
	var chan = this.channel ;
	if (newChan)
	{
		chan = newChan ;
	}
	if (chan == SearchList.SELECT.ANY_CHAN)
	{
		chan = "" ;
	}
	this.channel = chan ;
	return chan ;
}

/*------------------------------------------------------------------------------------------------------*/
//Build a new selector array
SearchList.prototype.chan_select_array = function()
{
	// Get list of channels (based on listings type)
	var channels = [] ;
	var anyChans = SearchList.SELECT.ANY_CHAN ;
	channels.push(anyChans) ;
	
	var type = this.typeValue() ;
//	var re = new RegExp(type.replace('-', '\-')) ;
	var re = new RegExp(type) ;
	var chansList = this.settings.app.allChansList.values() ;
	for (var i=0, len=chansList.length; i<len; i++)
	{
		if (chansList[i].show)
		{
			// check type (match hd-tv & tv with type 'tv')
			if (!type || (chansList[i].type.search(re) >= 0))
			{
				channels.push(chansList[i].name) ;
			}
		}
	}

	return channels ;
}

/*------------------------------------------------------------------------------------------------------*/
// Convert channel fullnames into list of truncated names
SearchList.prototype.chan_names_array = function(channels)
{
	var channelNames = [] ;
	for (var i=0, len=this.channels.length; i<len; i++)
	{
		var name = this.channels[i] ;
		var nameLen = name.length ;
		if (name.length > SearchList.settings.CHAN_MAX_LEN)
		{
			name = name.substr(0, SearchList.settings.CHAN_MAX_LEN-3) + '...' ;
		}
		channelNames[i] = name ;
	}
	
	return channelNames ;
}



/*------------------------------------------------------------------------------------------------------*/
//Build a new selector array
SearchList.prototype.update_rec_sel = function()
{
	if (!this.recList) return ;
	
	// show/hide any entries in the list that require the channel name specified
	var children = this.recList.reqChannel ;
	
	var channel = this.chanValue() ;
	for (var i=0, len=children.length; i<len; i++)
	{
		if (channel)
		{
			// ok to show
			$(children[i]).show() ;
		}
		else
		{
			// hide
			$(children[i]).hide() ;
		}
	}

}
	
/*------------------------------------------------------------------------------------------------------*/
// Build a new selector array
SearchList.prototype.update_chan_select = function()
{
	// Get list of channels (based on listings type)
	this.channels = this.chan_select_array() ;
	var channelNames = this.chan_names_array(this.channels) ;

	// Re-add new list
	var newSelect = document.createElement("select");
	for (var i=0, len=this.channels.length; i<len; i++)
	{
		var option = document.createElement("option");
		option.setAttribute('value', this.channels[i]) ; 
		if (this.channel == this.channels[i])
			option.setAttribute('selected', 'selected') ; 
		option.appendChild(document.createTextNode(channelNames[i])) ;
		newSelect.appendChild(option) ;
	}
	
	var select = this.chanSelector ;
	var changeHandler = select.changeHandler ;
	
	var selectParent = select.parentNode ;
	selectParent.replaceChild(newSelect, select) ;
	this.chanSelector = newSelect ;

	if (changeHandler)
	{
		newSelect.changeHandler = changeHandler ;
		$(newSelect).change(changeHandler) ;
	}
	
}



/*------------------------------------------------------------------------------------------------------*/
// Display the channel name selector
SearchList.prototype.display_chan_select = function(ol)
{
	// Get list of channels
	this.channels = this.chan_select_array() ;
	var channelNames = this.chan_names_array(this.channels) ;
	var anyChans = SearchList.SELECT.ANY_CHAN ;
	
	function createChangeHandler(searchObject) {
		return function() {
			var value = searchObject.chanValue(searchObject.channels[this.selectedIndex]) ;
			
			log.debug("chan change handler : value "+value);			
			
			// Ensure the recording select "dialog" shows the correct options
			searchObject.update_rec_sel() ;

			// save for re-use when changing recordings
			SearchList.copySearch(searchObject, SearchList.latestSearch) ;
		} ;
	}
	
	// create selector
	this.chanSelector = this.display_labelled_select(ol, 
			SearchList.settings.LABEL_CHAN_PX, 'Channel:', 
			SearchList.settings.EDIT_CHAN_PX, this.channel, this.channels, channelNames, 
			'select',
			createChangeHandler(this)) ;
}

/*------------------------------------------------------------------------------------------------------*/
// Display the listings type selector
SearchList.prototype.display_type_select = function(ol)
{
	// Get list of channels
	var types = [] ;
	var anyTypes = SearchList.SELECT.ANY_TYPE ;
	
	types.push(anyTypes) ;
	types.push("TV") ;
	types.push("HD-TV") ;
	types.push("Radio") ;
		
	function createChangeHandler(searchObject) {
		return function() {
			
			//var options = this.options ;
			//var option = options[this.selectedIndex] ;
			//var value = searchObject.typeValue(option.value) ;
			//
			// this.options doesn't seem to work on PS3?
			var value = searchObject.typeValue(types[this.selectedIndex]) ;

			//log.debug("type change handler : value "+value+" idx="+ this.selectedIndex+" val="+option.value);			
			
			// Update the channel list
			searchObject.update_chan_select() ;
			
			// save for re-use when changing recordings
			SearchList.copySearch(searchObject, SearchList.latestSearch) ;
		} ;
	}
	
	// create selector
	this.typeSelector = this.display_labelled_select(ol, 
			SearchList.settings.LABEL_TYPE_PX, 'Type:', 
			SearchList.settings.EDIT_TYPE_PX, this.listingsType, types, types,
			'select',
			createChangeHandler(this)) ;
}


/*------------------------------------------------------------------------------------------------------*/
SearchList.prototype.popup_fuzzyrecsel_contents = function(popupDiv, record_select)
{
	popupDiv.className = this.popupClassName ;

	var recUl = document.createElement("ul");
	recUl.className = "recprog" ;

	Prog.create_recSelList(recUl, "FUZZY", SearchList.srchProg, record_select) ;
	
	popupDiv.appendChild(recUl) ;
	
	this.recList = recUl ;
	
	// Find all entries that rely on the channel name being specified
	this.recList.reqChannel = $(".chan", $(this.recList)).toArray() ;

	// Update the dialog based on the channel name selection 
	this.update_rec_sel() ;
	
}

/*------------------------------------------------------------------------------------------------------*/
//Add a popup window for recording selection on multiple lines of the TvList display. 
//
SearchList.prototype.add_fuzzy_record_popup = function(node)
{
	var thisObj = this ;
	
	// use this width
	var popup_width = thisObj.settings.POPUP_WIDTH_PX ;
	
	var progSettings = {
		//-----------------------------------------------------
		create_popup: function(settings, x, y, callback) {
			
			var popupDiv = document.createElement("div");
			thisObj.popup_fuzzyrecsel_contents(popupDiv, callback) ; 
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
				// Call the fuzzy record method
				var old_rec = progObject.record ;
				progObject.record = new_rec ;
				SearchList.setFuzzyRecordings(progObject);
				
			}

		}
	} ;
	
	PopupHandler.add_popup(node, progSettings) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add a record level selection element
SearchList.prototype.display_fuzzyrecsel = function(ol)
{
	// Container
	var li = this._display_li(ol, this.settings.REC_PX, "") ;
	
		var a = document.createElement("a");
		a.id = "fuzzyrecsel" ;
		li.appendChild(a) ;

		this.fuzzyrecsel = a ;
		
			var img = document.createElement("img");
			img.src = Prog.RecImg(0) ; 
			a.appendChild(img) ;

			// add a popup display to show program details
			this.add_fuzzy_record_popup(a) ;
			
	return li ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add a record level selection element
SearchList.prototype.display_searchButton = function(ol)
{
	// Container
	var li = this._display_li(ol, this.settings.SEARCH_PX, "") ;
	
		var a = document.createElement("a");
		a.id = "searchButton" ;
		a.setAttribute("title", "Click to search for specified program(s)") ;
		li.appendChild(a) ;
		
		this.searchButton = a ;
	
			var img = document.createElement("img");
			
			// TODO: sort out image cache etc
			img.src = this.settings.app.getImage("search") ;
			a.appendChild(img) ;
			
	var app = SearchList.settings.app ;
	$(a).click(app.create_handler(app.showSearch, SearchList.latestSearch)) ; 

	return li ;
}



/*------------------------------------------------------------------------------------------------------*/
// Update the search params - passed in via JSON
//
SearchList.prototype.update_search = function(search_data)
{
	Profile.start('SearchList.update') ;

	// Create a mapping from name -> value
	var entry_args = [] ;
	for (var i in SearchList.SEARCH_MAP)
	{
		var field = SearchList.SEARCH_MAP[i] ;
		if (search_data[i])
		{
			this[field] = search_data[i] ;
		}
	}

	Profile.stop('SearchList.update') ;
}


/*------------------------------------------------------------------------------------------------------*/
//Create a text editor
//
SearchList.prototype.factory_edit_search = function(type)
{
var searchList = this ;

	return function(node) {
		
		//----------------------------------------------------------------------------
		// Value change callback
		function search_change(searchObject, new_val) {
			
			// only update if changed
			if (new_val != searchObject[type])
			{
				searchObject[type] = new_val ;
				SearchList.copySearch(searchObject, SearchList.latestSearch) ;
				
				// amend the gui to reflect the latest search settings
				searchObject.updateSearchForm() ;
			}
		}
		
		// Create the text edit
		$(node).change(function(){search_change(searchList, node.value)})
	} ;
}


/*------------------------------------------------------------------------------------------------------*/
// Recalc the search bar item sizes
SearchList.prototype.sizeSearchBar = function()
{
	// Adjust the main search bar elements so they fit the window width
	if (!this.searchBar) return ;
	
	// find labels & editors
	var sb$ = $(this.searchBar) ;
	var labels = $('.edLabel', sb$).toArray() ;
	var editors = $('.editor', sb$).toArray() ;

	var labelsWidth=0;
	var numLabels = labels.length ;
	for (var i=0; i<numLabels; i++)
	{
		labelsWidth += $(labels[i]).width() ;
	}

	var selectWidth=SearchList.settings.EDIT_CHAN_PX + SearchList.settings.EDIT_TYPE_PX;

	var inputWidth = 0 ;
	var minWidth = 0 ;
	var numInputs = editors.length ;
	for (var i=0; i<numInputs; i++)
	{
		inputWidth += $(editors[i]).width() ;
		minWidth += SearchList.settings.EDIT_MIN_PX ;
	}
	
	// get total available space - remove fixed items
	var available = SearchList.settings.TOTAL_PX - (
		SearchList.settings.REC_PX +
		SearchList.settings.SEARCH_PX +
		selectWidth +
		SearchList.settings.END_MARGIN_PX
	) ;
	
	//	Total > available:
	//
	//	<---------------------available---------------------->
	//	<-label-><--input----><-label-><--input---><-label-><--input------>
	//	                                                |- - -diff - - - ->|
	//	<-label-><-min-><-label-><-min-><-label-><-min->
	//	
	//	diff = inputs - labels
	//	

	//	Total < available:
	//
	//	<---------------------available-------------------------------------------->
	//	                                                                  |- diff ->|
	//	<-label-><--input----><-label-><--input---><-label-><--input------>
	//	diff = available - (inputs - labels)
	//	
	
	// Does this currently fit (i.e. need to expand)?
	if (available > (inputWidth + labelsWidth) )
	{
		// resize inputs
		var diff = parseInt( (available - (inputWidth + labelsWidth)), 10) ;
		var delta = parseInt( diff / numInputs, 10) ;
		for (var i=0; i<numInputs; i++)
		{
			DomUtils.incChildWidths(editors[i], delta) ;
			diff -= delta ;
		}
		
	}
	
	
	// can we resize just the inputs
	else if ( (available-labelsWidth) >= minWidth)
	{
		// resize inputs
		var diff = parseInt( (inputWidth-minWidth), 10) ;
		var delta = parseInt( diff / numInputs, 10) ;
		for (var i=0; i<numInputs; i++)
		{
			DomUtils.incChildWidths(editors[i], -delta) ;
			diff -= delta ;
		}
		if (diff > 0)
			DomUtils.incChildWidths(editors[0], -diff) ;
		
	}
	else
	{
		// Need to set all inputs to minumum size then try resizing labels
		for (var i=0; i<numInputs; i++)
		{
			var width = parseInt(editors[i].style.width, 10) ;
			var delta = width - SearchList.settings.EDIT_MIN_PX ;
			DomUtils.incChildWidths(labels[i], delta) ;
		}
		available -= minWidth ;
		
		// resize labels
		if (available > labelsWidth)
		{
			// increase labe lsize
			var diff = parseInt( (available > labelsWidth), 10) ;
			var delta = parseInt( diff / numLabels, 10) ;
			for (var i=0; i<numLabels; i++)
			{
				DomUtils.incChildWidths(labels[i], delta) ;
				diff -= delta ;
			}
		}
		else
		{
			// reduce label size (min=0)
			var delta = parseInt( available / numLabels, 10) ;
			for (var i=0; i<numLabels; i++)
			{
				DomUtils.incChildWidths(labels[i], -delta) ;
				available -= delta ;
			}
		}
		
	}
}


/*------------------------------------------------------------------------------------------------------*/
// Updates the state iof the "form"
SearchList.prototype.updateSearchForm = function()
{
	// Can't do search without some search string
	var canSearch = 0 ;
	for (var i in SearchList.SEARCH_MAP)
	{
		var field = SearchList.SEARCH_MAP[i] ;
		if (this[field])
		{
			canSearch = 1 ;
		}
	}
	if (!canSearch)
	{
		this.searchButton.style.visibility = "hidden";
	}
	else
	{
		this.searchButton.style.visibility = "visible";
	}

	// Can't set recording without title
	if (!this.title)
	{
		this.fuzzyrecsel.style.visibility = "hidden";
	}
	else
	{
		this.fuzzyrecsel.style.visibility = "visible";
	}
	
	
	// Adjust widths
	
}




/*------------------------------------------------------------------------------------------------------*/
//Display a list entry
SearchList.prototype.search_row = function(ol)
{
	this.searchBar = ol ;
	
	this.display_fuzzyrecsel(ol) ;
	this.display_searchButton(ol) ;
	
	// Title
	this.display_labelled_edit(ol, SearchList.settings.LABEL_TITLE_PX, 'Title:', SearchList.settings.EDIT_TITLE_PX, this.title, this.factory_edit_search('title'), 'editor') ;

	// Genre
	this.display_labelled_edit(ol, SearchList.settings.LABEL_GENRE_PX, 'Genre:', SearchList.settings.EDIT_GENRE_PX, this.genre, this.factory_edit_search('genre'), 'editor') ;

	// Listings Type
	this.display_type_select(ol) ;

	// Channel
	this.display_chan_select(ol) ;


	// Description
	this.display_labelled_edit(ol, SearchList.settings.LABEL_DESC_PX, 'Description:', SearchList.settings.EDIT_DESC_PX, this.desc, this.factory_edit_search('desc'), 'editor') ;

	// End
	this.display_empty(ol, SearchList.settings.END_MARGIN_PX) ;
	
	// Ensure "form" reflects the current state
	this.updateSearchForm() ;
	
//	// Run the other updates
//	this.update_chan_select() ;
}

