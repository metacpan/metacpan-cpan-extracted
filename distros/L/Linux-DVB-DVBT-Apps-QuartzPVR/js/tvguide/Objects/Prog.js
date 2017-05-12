/*
Manages a single program on a channel

*/

// Create the popup object we'll use
Prog.popup = new Popup();

Prog.settings = {} ;

//Map from array index to prog field
Prog.PROG_MAP = {
	0	: "pid", 
	1	: "chanid", 
	2	: "start_time", 
	3	: "start_date", 
	4	: "end_time", 
	5	: "end_date", 
	6	: "duration_mins", 
	7	: "title", 
	8	: "genre", 
	9	: "description", 
	10	: "record",
	11	: "pvr",
	12	: "tva_series"
} ;

// Optional extra info
Prog.PROG_EXTRA_MAP = {
	13	: "rid", 
	14	: "priority" 
} ;

// filled in during init
Prog.PROG_FIELDS = {} ;

// Image cache
Prog.ImageCache = {} ;

Prog.REC_MAX = 0xFF ;
Prog.REC_MASK = 0x1F ;
Prog.REC_GROUP_MASK = 0xE0 ;
Prog.REC_GROUPS = {
	'DVBT'			: 0x00,	
	'FUZZY'			: 0x20,	
	'DVBT_IPLAY'	: 0xC0,
	'IPLAY'			: 0xE0
} ;
//  'DVBT(alt)'		: 0x10,	

// create a list of the group names in correct ascending order
Prog.REC_GROUP_LIST = [] ;
for (var group in Prog.REC_GROUPS)
{
	Prog.REC_GROUP_LIST.push(group) ;
}
Prog.REC_GROUP_LIST = Prog.REC_GROUP_LIST.sort(function(a,b){return Prog.REC_GROUPS[a] - Prog.REC_GROUPS[b]}) ;

// map group name to "page" for tabbed record entry 
Prog.REC_GROUP_PAGE = {} ;
for (var i in Prog.REC_GROUP_LIST)
{
	Prog.REC_GROUP_PAGE[ Prog.REC_GROUP_LIST[i] ] = parseInt(i, 10) ;
}

// Create lookup from record value to group name
Prog.REC_GROUP_LOOKUP = {} ;
Prog.create_group_lookup = function()
{
	var groups = {} ;
	for (var i in Prog.REC_GROUPS)
	{
		groups[i] = Prog.REC_GROUPS[i] ;
	}
	groups["MAX"] = Prog.REC_MAX +1 ;
	
	var list = [] ;
	list = list.concat(Prog.REC_GROUP_LIST) ;
	list.push("MAX") ;
	
	var grp_idx = 0 ;
	var group = Prog.REC_GROUP_LIST[grp_idx] ;
	var grp_max = groups[ list[grp_idx+1] ] -1 ;
	for (var i=0; i <= Prog.REC_MAX; i++)
	{
		if (i > grp_max)
		{
			// move to next group
			++grp_idx ;
			group = Prog.REC_GROUP_LIST[grp_idx] ;
			grp_max = groups[ list[grp_idx+1] ] -1 ;
		}
		
		Prog.REC_GROUP_LOOKUP[i] = group ;
	}
}
Prog.create_group_lookup() ;


Prog.REC_SET = {
		'NONE'		: 0,	
		'ONCE'		: 1,	
		'WEEKLY'	: 2,	
		'DAILY'		: 3,	
		'MULTI'		: 4,	
		'ALL'		: 5,	
		'SERIES'	: 6	
	} ;

Prog.REC_SET_LOOKUP = {} ;
Prog.create_recset_lookup = function()
{
	for (var name in Prog.REC_SET)
	{
		var rec = parseInt(Prog.REC_SET[name], 10) ;
		Prog.REC_SET_LOOKUP[rec] = name ;
	}
}
Prog.create_recset_lookup() ;



// Channel name required
Prog.REC_CHAN_REQ = {
		'NONE'		: 0,	
		'ONCE'		: 1,	
		'WEEKLY'	: 1,	
		'DAILY'		: 1,	
		'MULTI'		: 1,	
		'ALL'		: 0,	
		'SERIES'	: 1	
	} ;

Prog.MAP = {
	'RECORD'	: {
		'DVBT'			: [
			{ val : Prog.REC_SET.NONE, 							img : "record-none", 		label : "No recording" },
			{ val : Prog.REC_GROUPS.DVBT+Prog.REC_SET.ONCE, 	img : "record-once", 		label : "Record once"},
			{ val : Prog.REC_GROUPS.DVBT+Prog.REC_SET.WEEKLY, 	img : "record-weekly", 		label : "Record weekly"},
			{ val : Prog.REC_GROUPS.DVBT+Prog.REC_SET.DAILY, 	img : "record-daily", 		label : "Record daily"},
			{ val : Prog.REC_GROUPS.DVBT+Prog.REC_SET.MULTI, 	img : "record-multi",		label : "Record any showing on this channel"},
			{ val : Prog.REC_GROUPS.DVBT+Prog.REC_SET.ALL, 		img : "record-all", 		label : "Record any showing, any channel"},
			{ val : Prog.REC_GROUPS.DVBT+Prog.REC_SET.SERIES,	img : "record-series", 		label : "Record program series"}
		],	
		'IPLAY'			: [
			{ val : Prog.REC_SET.NONE, 							img : "record-none", 		label : "No recording" },
			{ val : Prog.REC_GROUPS.IPLAY+Prog.REC_SET.ONCE, 	img : "iplay-once", 		label : "Get iplay once"},
			{ val : Prog.REC_GROUPS.IPLAY+Prog.REC_SET.WEEKLY, 	img : "iplay-weekly", 		label : "Get iplay weekly"},
			{ val : Prog.REC_GROUPS.IPLAY+Prog.REC_SET.DAILY, 	img : "iplay-daily", 		label : "Get iplay daily"},
			{ val : Prog.REC_GROUPS.IPLAY+Prog.REC_SET.MULTI, 	img : "iplay-multi",		label : "Get iplay any showing on this channel"},
			{ val : Prog.REC_GROUPS.IPLAY+Prog.REC_SET.ALL, 	img : "iplay-all", 			label : "Get iplay any showing, any channel"}
		],	
		'FUZZY'			: [
			{ val : Prog.REC_SET.NONE, 							img : "record-none", 		label : "No recording" },
//			{ val : Prog.REC_GROUPS.FUZZY+Prog.REC_SET.ONCE, 	img : "fuzzy-once", 		label : "Fuzzy record once"},
//			{ val : Prog.REC_GROUPS.FUZZY+Prog.REC_SET.WEEKLY, 	img : "fuzzy-weekly", 		label : "Fuzzy record weekly"},
//			{ val : Prog.REC_GROUPS.FUZZY+Prog.REC_SET.DAILY, 	img : "fuzzy-daily", 		label : "Fuzzy record daily"},
			{ val : Prog.REC_GROUPS.FUZZY+Prog.REC_SET.MULTI, 	img : "fuzzy-multi",		label : "Fuzzy record any showing on this channel"},
			{ val : Prog.REC_GROUPS.FUZZY+Prog.REC_SET.ALL, 	img : "fuzzy-all", 			label : "Fuzzy record any showing, any channel"}
			
		],	
		'DVBT_IPLAY'	: [
			{ val : Prog.REC_SET.NONE, 								img : "record-none", 		label : "No recording" },
			{ val : Prog.REC_GROUPS.DVBT_IPLAY+Prog.REC_SET.ONCE, 	img : "rec-iplay-once", 	label : "Record / get iplay once"},
			{ val : Prog.REC_GROUPS.DVBT_IPLAY+Prog.REC_SET.WEEKLY, img : "rec-iplay-weekly", 	label : "Record / get iplay weekly"},
			{ val : Prog.REC_GROUPS.DVBT_IPLAY+Prog.REC_SET.DAILY, 	img : "rec-iplay-daily", 	label : "Record / get iplay daily"},
			{ val : Prog.REC_GROUPS.DVBT_IPLAY+Prog.REC_SET.MULTI, 	img : "rec-iplay-multi", 	label : "Record / get iplay any on this channel"},
			{ val : Prog.REC_GROUPS.DVBT_IPLAY+Prog.REC_SET.ALL, 	img : "rec-iplay-all", 		label : "Record / get iplay any showing"}
		]
	},
	'PRIORITY'	: [
		{ val : 500, 	img : "priority-none", 		label : "Only record if resources allow" },
		{ val : 100, 	img : "priority-low", 		label : "Lowest priority"},
		{ val : 75, 	img : "priority-lowmedium", label : "Low/Medium priority"},
		{ val : 50, 	img : "priority-medium", 	label : "Medium priority (default)"},
		{ val : 25, 	img : "priority-mediumhigh",label : "Medium/High priority"},
		{ val : 1, 		img : "priority-high", 		label : "Highest priority (always record)"}
	]
} ;

Prog.DEFAULT_PRIORITY = 50 ;

Prog.MAP_LOOKUP = {} ;
/*------------------------------------------------------------------------------------------------------*/
//Create a "copy" of the map definitions, but use the real record value 
Prog.createMapLookup = function()
{
	if (!Prog.MAP_LOOKUP.RECORD)
	{
		Prog.MAP_LOOKUP.RECORD = {} ;
		for (var group in Prog.REC_GROUPS)
		{
			Prog.MAP_LOOKUP.RECORD[group] = [] ;
			for (var rec in Prog.MAP.RECORD[group])
			{
				var recObj = Prog.MAP.RECORD[group][rec] ;
				var recVal = recObj.val - Prog.REC_GROUPS[group] ;
				Prog.MAP_LOOKUP.RECORD[group][recVal] = recObj ;
			}
		}
	}
}
Prog.createMapLookup() ;


// Debug
Prog.DEBUG = {
	popup : 1
} ;

//Set to true to globally enable debugging
Prog.prototype.logDebug = 0 ;



/*------------------------------------------------------------------------------------------------------*/
// Constructor
//
// Create from an array of values (see PROG_MAP)
//
function Prog(args)
{
	// if no args specified, then just create object (with functions)
	if (args)
	{
// log.dbg(this.logDebug, " + Prog()") ;
		this.type = 'Prog' ;
		
		// These fields MUST be present
		for (var i in Prog.PROG_MAP)
		{
			var field = Prog.PROG_MAP[i] ;
			this[field] = null ;
			if (args[i])
			{
				this[field] = args[i] ;
			}
		}
		
		// Some variants will include one or more of these optional elements
		for (var i in Prog.PROG_EXTRA_MAP)
		{
			var field = Prog.PROG_EXTRA_MAP[i] ;
			this[field] = null ;
			if (args.hasOwnProperty(i))
			{
				this[field] = args[i] ;
			}
		}
		
		if (!this.pvr) this.pvr = 0 ;
		
		// Check for film
		this.film = false ;
		if (this.genre)
		{
			if (this.genre.search(/film/i) >= 0)
			{
				this.film = true ;
			}
		}

		// log.dbg(this.logDebug, " + Prog : start "+this.start_date+" "+this.start_time+", end "+this.end_date+" "+this.end_time) ;
		
		// calc
		this.duration_mins = parseInt(this.duration_mins, 10) ;
		this.start_mins = DateUtils.datetime2mins(this.start_date, this.start_time) ;
		this.end_mins = DateUtils.datetime2mins(this.end_date, this.end_time) ;
		
		// DOM vars
		this.dom_node = null ;
		
		// Can we IPLAY record this program (channel)?
		this.canIPLAY = false ;
		if (Prog.settings.app.allChans[this.chanid])
		{
			this.canIPLAY = Prog.settings.app.allChans[this.chanid].iplay ;
		}

// log.dbg(this.logDebug, " + Prog() - END") ;
	}
	
	// Point to global settings
	this.settings = Prog.settings ;
	
}



/*------------------------------------------------------------------------------------------------------*/
// Set the display windows
// start date & hour, display period in hours
//
Prog.setup = function(settings)
{
	if (!Prog.settings)
	{
		Prog.settings = {} ;
	}
	
	for (var setting in settings)
	{
		Prog.settings[setting] = settings[setting] ;
	}

	Prog.cacheImages() ;
}

/*------------------------------------------------------------------------------------------------------*/
Prog.cacheImages = function()
{
	var themePath = Settings.themePath() ;

	// Pre-load Prog images
	for (var group in Prog.REC_GROUPS)
	{
		for (var rec in Prog.MAP.RECORD[group])
		{
			var recObj = Prog.MAP.RECORD[group][rec] ;
			if (!recObj.imgCache)
			{
				recObj.imgCache = new Image() ;
//				recObj.imgCache.src = themePath + '/images/' + recObj.img + '.png' ;
				recObj.imgCache.src = this.settings.app.imgPath(recObj.img) ;
			}
		}
	}
	for (var pri in Prog.MAP.PRIORITY)
	{
		var priObj = Prog.MAP.PRIORITY[pri] ;
		if (!priObj.imgCache)
		{
			priObj.imgCache = new Image() ;
//			priObj.imgCache.src = themePath + '/images/' + priObj.img + '.png' ;
			priObj.imgCache.src = this.settings.app.imgPath(priObj.img) ;
		}
	}
	
	// General
	Prog.IconImg('icon_film') ;
	Prog.IconImg('icon_dir') ;
}

/*------------------------------------------------------------------------------------------------------*/
// Get an icon
Prog.IconImg = function(name)
{
	if (!Prog.ImageCache[name])
	{
		var themePath = Settings.themePath() ;
		Prog.ImageCache[name] = new Image() ;
//		Prog.ImageCache[name].src = themePath + '/images/' + name + '.png' ;
		Prog.ImageCache[name].src = this.settings.app.imgPath(name) ;
	}
	
	return Prog.ImageCache[name].src ;
}

/*------------------------------------------------------------------------------------------------------*/
//Given a record setting, return the image
//
// NOTE: Use MAP_LOOKUP (rather than MAP) because the arrays are built with an entry for each record
// value
//
Prog.RecImg = function(record)
{
	var recGroup = record & Prog.REC_GROUP_MASK ;
	var rec = record & Prog.REC_MASK ;
	var recObjs = Prog.MAP_LOOKUP.RECORD.DVBT ;
	switch (recGroup)
	{
		case Prog.REC_GROUPS.DVBT:
			recObjs = Prog.MAP_LOOKUP.RECORD.DVBT ;
			break ;
			
		case Prog.REC_GROUPS.IPLAY:
			recObjs = Prog.MAP_LOOKUP.RECORD.IPLAY ;
			break ;
			
		case Prog.REC_GROUPS.FUZZY:
			recObjs = Prog.MAP_LOOKUP.RECORD.FUZZY ;
			break ;
			
		case Prog.REC_GROUPS.DVBT_IPLAY:
			recObjs = Prog.MAP_LOOKUP.RECORD.DVBT_IPLAY ;
			break ;
			
	}
	
if (!recObjs.hasOwnProperty(rec))
{
	rec = 0 ;
}
	
	var img = recObjs[rec].imgCache ;

	return img.src ;
}

/*------------------------------------------------------------------------------------------------------*/
//Returns true if record level has any DVB-T recording (i.e. not all IPLAY)
Prog.hasDVBT = function(record)
{
	return record < Prog.REC_GROUPS['IPLAY'] ? 1 : 0 ;
}

/*------------------------------------------------------------------------------------------------------*/
//Returns true if record level has any IPLAY recording 
Prog.hasIPLAY = function(record)
{
	return record >= Prog.REC_GROUPS['DVBT_IPLAY'] ? 1 : 0 ;
}

/*------------------------------------------------------------------------------------------------------*/
//Returns true if record level has any IPLAY recording 
Prog.hasOnlyIPLAY = function(record)
{
	return record >= Prog.REC_GROUPS['IPLAY'] ? 1 : 0 ;
}

/*------------------------------------------------------------------------------------------------------*/
//Returns true if record level is a fuzzy recording
Prog.isFuzzy = function(record)
{
	var recGroup = record & Prog.REC_GROUP_MASK ;
	return recGroup == Prog.REC_GROUPS['FUZZY'] ? 1 : 0 ;
}

/*------------------------------------------------------------------------------------------------------*/
//Returns true if record level requires a channel name to be specified
Prog.recRequiresChan = function(record)
{
	var recType = record & Prog.REC_MASK ;
	var recName = Prog.REC_SET_LOOKUP[recType] ;
	return Prog.REC_CHAN_REQ[recName] ;
}



/*------------------------------------------------------------------------------------------------------*/
//Given a priority setting, return the image
Prog.PriImg = function(pri)
{
	var priObjs = Prog.MAP.PRIORITY ;
	var img = priObjs[pri].imgCache ;

	return img.src ;
}


/*------------------------------------------------------------------------------------------------------*/
//Given a priority setting, return the image
Prog.PriorityImg = function(priority)
{
	var priObjs = Prog.MAP.PRIORITY ;
	
	// ensure priority value is one of the standard values
	var pri = Prog.priIndex(parseInt(priority, 10)) ;
	return Prog.PriImg(pri) ;
}




/*------------------------------------------------------------------------------------------------------*/
// Filter for sorted list - returns true if this program should be displayed in the grid (i.e. it's start/end
// times are to be shown)
Prog.prog_in_display = function(prog)
{
	var display=false ;
	if ((prog.end_mins > Prog.settings.DISPLAY_START_MINS) && (prog.start_mins < Prog.settings.DISPLAY_END_MINS))
	{
		display = true ;
	}
	
	return display ;
}

/*------------------------------------------------------------------------------------------------------*/
// Sort 2 programs
Prog.prog_sort = function(a, b) 
{
	return a.start_mins - b.start_mins ;
}




/*------------------------------------------------------------------------------------------------------*/
Prog.check_prog_display = function(prev_prog, prog, start_x)
{

	// get displayed position
	var node_x = $(prog.dom_node).pos().left ;

	// calc where it should be
	var mins_from_start = prog.start_mins - Prog.settings.DISPLAY_START_MINS ;
	if (mins_from_start < 0)
	{
		mins_from_start = 0 ;
	}
	var expected_x = (mins_from_start * Prog.settings.PX_PER_MIN) + start_x ;
	
	var delta = expected_x - node_x ;
	
	// log.dbg(this.logDebug, "check_prog_display("+prog.title+") expected x="+expected_x+", got="+node_x) ;

// DEBUG
var prev_exp_width = prev_prog._display_mins * Prog.settings.PX_PER_MIN ;
var prev_width = parseInt(prev_prog.dom_node.style.width, 10) ;
// log.dbg(this.logDebug, " + previous("+prev_prog.title+") expected width="+prev_exp_width+", got="+prev_width+" (display="+prev_prog._display_mins+")") ;
// log.dbg(this.logDebug, " + offset width="+prev_prog.dom_node.offsetWidth+", scroll width="+prev_prog.dom_node.scrollWidth) ;

var curr_exp_width = prog._display_mins * Prog.settings.PX_PER_MIN ;
var curr_width = parseInt(prog.dom_node.style.width, 10) ;
// log.dbg(this.logDebug, " + prog expected width="+curr_exp_width+", got="+curr_width+" (display="+prog._display_mins+")") ;
// log.dbg(this.logDebug, " + offset width="+prog.dom_node.offsetWidth+", scroll width="+prog.dom_node.scrollWidth) ;

	
	// if it's different (i.e. IE!) then correct it by adjusting the previous node's width
	if (delta != 0)
	{
		var curr_width = parseInt(prev_prog.dom_node.style.width, 10) ;
		var new_width = (curr_width+delta) ;
		if (new_width < 0)
		{
			// previous is too small, leave until next prog to take up the slack
			new_width=curr_width ;
			// log.dbg(this.logDebug, " ++ attempt to set -ve width! "+new_width) ;

			// When all else fails, modify the text to allow block to be set to correct size
			
		}
		
		// if block has wrapped on to next line, then delta will be +ve
		prev_prog.dom_node.style.width = new_width + "px" 

		// log.dbg(this.logDebug, " + adjusted by="+delta) ;
	}
	
	// Also adjust this prog's width if it doesn't match
	
	// TODO.....
}




/*------------------------------------------------------------------------------------------------------*/
//Create a list of icon/label pairs with an associated handler. Driven by the data in a table
Prog.create_selList = function (data, node, progObj, itemClass, selectVal, select_callback)
{
	for (var i = 0; i < data.length; i++)
	{				
		var val = data[i].val ;
		var cName = itemClass ;
		if (val == selectVal)
		{
			cName += " sel" ;
		}
		
		// set a "flag" if this option requires a channel name
		if (Prog.recRequiresChan(val))
		{
			cName += " chan" ;
		}
		
		var radioSpan = document.createElement("li");
		radioSpan.className = cName ;
		node.appendChild(radioSpan) ;
		
			var a = document.createElement("a");
			// set title otherwise Android does not recognise link
			a.setAttribute("title", data[i].label) ;	
			radioSpan.appendChild(a) ;
		
			var img = document.createElement("img");
			img.src = data[i].imgCache.src ; 
			a.appendChild(img) ;
			
			a.appendChild(document.createTextNode(" " + data[i].label)) ;


			// Add event handlers
			function sel_handler(progObject, newVal)
			{
			   	return function() { select_callback( {
				   		prog : progObject, 
				   		val  : newVal 
			   		}); 
			   	} ;
			} 
			$(radioSpan).click( sel_handler(progObj, val) ) ;
	}

	return node ;
}




/*------------------------------------------------------------------------------------------------------*/
//Adds the list of record select elements to an existing UL
Prog.create_recSelList = function(ul, recGroup, progObj, rec_callback)
{
	ul = Prog.create_selList(Prog.MAP.RECORD[recGroup], ul, progObj, "recradio", progObj.record, rec_callback) ;
	return ul ;
}


/*------------------------------------------------------------------------------------------------------*/
// Creates a tabbed page of record seelct options. Builds the tabs into the specified parent node
Prog.create_recSelTabs = function(node, progObj, rec_callback)
{
	// Set tabs
	var tabList = new TabList("rectype", "recopt") ;
	var tabs = [] ;
	var groupOk = {} ;
	for (var i in Prog.REC_GROUP_LIST)
	{
		var group = Prog.REC_GROUP_LIST[i] ;
		groupOk[group] = true ;
		if (Prog.hasIPLAY(Prog.REC_GROUPS[group]))
		{
			// Group has IPLAY record, can this program do IPLAY?
			if (!progObj.canIPLAY)
			{
				groupOk[group] = false ;
			}
		}
		
		if (groupOk[group])
		{
			tabs.push(group) ;
		}
	}
	tabList.setTabs(tabs) ;
	
	// add pages
	var page = 1 ;
	for (var i in Prog.REC_GROUP_LIST)
	{
		var group = Prog.REC_GROUP_LIST[i] ;
		if (groupOk[group])
		{
			// Only add this page if the prog can handle the recording type
			var ul = document.createElement("ul");
			ul.className = "recsel" ;
			ul = Prog.create_recSelList(ul, group, progObj, rec_callback);
			tabList.setPage(page, ul) ;
			
			page++ ;
		}
	}
	
	// set active page
	var group = Prog.REC_GROUP_LOOKUP[progObj.record] ;
	var currPage = Prog.REC_GROUP_PAGE[ group ] ;
	if (currPage < page)
	{
		tabList.activePage(  currPage +1 ) ;
	}
	
	// create DOM
	tabList.createDom(node) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Create DIV containing the recording selection
Prog.create_recsel = function(progObj, this_record, rec_callback)
{
	//
	//	<ul class="recprog">
	//	
	//		<li class="sub">
	//			<a ><img src="record-once"></a>
	//
	//			<div class="recDiv">
	//				..contents
	//			</div>
	//		</li>
	//	</ul>
	//
	var recUl = document.createElement("ul");
	recUl.className = "recprog" ;
	
		var recLi = document.createElement("li");
		recLi.className = "sub" ;
		recUl.appendChild(recLi) ;
	
			var a = document.createElement("a");
			a.setAttribute("title", "Click to show/hide recording settings") ;
			recLi.appendChild(a) ;	
			
				var img = document.createElement("img");
				img.src = Prog.RecImg(this_record) ;
				a.appendChild(img) ;	
		
			// Start with div hidden
			var recDiv = document.createElement("div");
			recDiv.className = "recdiv" ;
			recDiv.style.display = "none" ;
			recLi.appendChild(recDiv) ;
			
////debug
//recDiv._dbgName = progObj.title ;			
			
			// Add list of record options (with handler for each)
			Prog.create_recSelTabs(recDiv, progObj, rec_callback) ;
	
			// Add handler AFTER adding the child nodes
			$(a).click(function () {
				$(this).closest('.recprog').find('.recdiv').toggle() ;
			}) ;

	return recUl ;
}




/*------------------------------------------------------------------------------------------------------*/
// Adds the list of priority select elements to an existing UL
Prog.create_priSelList = function(ul, progObj, pri_callback)
{
	ul = Prog.create_selList(Prog.MAP.PRIORITY, ul, progObj, "recradio", progObj.priority, pri_callback) ;
	return ul ;
}




/*------------------------------------------------------------------------------------------------------*/
// Convert from a real priority value to the nearest priority index
Prog.priIndex = function(this_priority)
{
	var pri = 0 ;
	for (var i=0; i < Prog.MAP.PRIORITY.length; i++)
	{					
		var priVal = Prog.MAP.PRIORITY[i].val ;
		if (this_priority <= priVal)
		{
			// actual value is same or higher level of priority
			pri = i ;
		}
	}
	
	return pri ;
}





/*------------------------------------------------------------------------------------------------------*/
//Returns true if record level has any DVB-T recording (i.e. not all IPLAY)
Prog.prototype.hasDVBT = function()
{
	return Prog.hasDVBT(this.record) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Returns true if record level has any IPLAY recording 
Prog.prototype.hasIPLAY = function()
{
	return Prog.hasIPLAY(this.record) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Returns true if record level has any IPLAY recording 
Prog.prototype.hasOnlyIPLAY = function()
{
	return Prog.hasOnlyIPLAY(this.record) ;
}




/*------------------------------------------------------------------------------------------------------*/
// Update from an array of values (see PROG_MAP)
//
Prog.prototype.update = function(args)
{
	for (var i in Prog.PROG_MAP)
	{
		var field = Prog.PROG_MAP[i] ;
		if (args[i])
		{
			this[field] = args[i] ;
		}
	}

}


/*------------------------------------------------------------------------------------------------------*/
Prog.prototype.popup_contents = function(popupDiv, record_select)
{
	var rid = -1 ;
	var recording = Prog.settings.app.grid.lookup_recording(this.pid) ;
	if (recording)
		rid = recording.rid ;
	
	var title = this.title ;
	if (Settings.debug())
	{
		title = '[RID:'+rid+' PID:'+this.pid+'] '+
	    		this.title+'</span>';
	}
	
	popupDiv.innerHTML = 
		'<span class="wrap">'+
		'<span class="times">'+
			'<span class="dtstart">'+
				'<abbr class="value" title="'+this.start_date+'T'+this.start_time+'"></abbr>'+
				this.start_time+
			'</span>'+
			'-'+
			'<span class="dtend">'+
				'<abbr class="value" title="'+this.end_date+'T'+this.end_time+'"></abbr>'+
				this.end_time+
			'</span>'+
		'</span>'+ 
	'</span>'+
	
	'<div class="description">'+
	    '<span class="summary">'+
	    Prog.settings.app.allChans[this.chanid].name+
	    '</span>'+
	    '<span class="summary">'+
	    title+
	    '</span>'+
	    this.description+
	'</div>' ;

	var recUl = Prog.create_recsel(this, this.record, record_select)
	popupDiv.appendChild(recUl) ;
}


/*------------------------------------------------------------------------------------------------------*/
Prog.prototype.add_prog_popup = function(node)
{
	var progobj = this ;

	// use this width
	var popup_width = Prog.settings.POPUP_WIDTH_PX ;
	
	var progSettings = {
		//-----------------------------------------------------
		create_popup: function(settings, x, y, callback) {
			
			var popupDiv = document.createElement("div");
			progobj.popup_contents(popupDiv, callback) ; 
			var popupObj = {
				dom 	: popupDiv,	
				top		: Prog.popup
			} ;
			
			// save popup in prog for debug
			progobj['_progPopup'] = popupObj ;
			
			return popupObj ;
		},
		//-----------------------------------------------------
		popup_node	: function(settings, popupObj) {
			return popupObj.dom ;
		},
		//-----------------------------------------------------
		show_popup	: function(settings, popupObj, x, y) {
			
			log.debug("Prog.show_popup()");		
			var popupDiv = popupObj.dom ;

			x = x + 10 ;
			y = y + 10 ;
			
			// Show the popup window
            Prog.popup.show(popupDiv, x, y, popup_width);
            
			//Check we haven't gone over the edge
            Prog.popup.adjustXY(x, y);
			log.debug("Prog.show_popup() - end x="+x+" y="+y);		
		},
		//-----------------------------------------------------
		hide_popup	: function(settings, popupObj) {
			Prog.popup.hide();
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
//				Prog.settings.app.set_rec(new_rec, progObject.chan, progObject.pid, progObject.record) ;
				Prog.settings.app.set_rec(progObject, old_rec) ;
			}

		}
	} ;
	
	if (Prog.settings.PROG_POPUP)
	{
		PopupHandler.add_popup(node, progSettings) ;
	}
	else
	{
		ClickHandler.add_popup(node, progSettings) ;
	}
}


/*------------------------------------------------------------------------------------------------------*/
// return the class name fotr recording - over ride with derived classes
Prog.prototype.record_class = function()
{
	return "record" ;
}

/*------------------------------------------------------------------------------------------------------*/
// Redisplay this prog if it's already on display
Prog.prototype.redisplay = function()
{
	// see if prog on display
	if (Prog.prog_in_display(this) && this.dom_node)
	{
		// create the program content - keep track of this for when we change the record settings etc
		var dom_content = this._create_content() ;
	
		// add content to wrapper
		this.dom_node.replaceChild(dom_content, this.dom_content);
		
		this.dom_content = dom_content ;
	}

}

/*------------------------------------------------------------------------------------------------------*/
// Add a prog to the DOM - append to specified node
Prog.prototype.display = function(node)
{
Profile.start("Prog.display") ;
/*
			<li style="width: 135px;" class="vevent">
				<a href="https://sdprice.plus.com/su/mediacentre/listings.php?dt=2009-08-07&amp;t=tv&amp;ch=1&amp;hr=12&amp;rec=53859-1-20090807" class="url uid">
					<span class="wrap">
						
						<span class="summary">
							Trash to Cash
						</span>
						
						<span class="category">
							<span class="Leisure">
							</span>
							Leisure
						</span>
	
					</span>
	
					<div class="description">
					    <span class="summary">Trash to Cash</span>
						Leisure: Preece: Geoff Preece wants to sell all his junk to raise money
						for a European cycling holiday. With Lorne Spicer. Then BBC News;
						Weather. 
					</div>  
 
				</a>
			</li> 
*/

//TODO: need to calc displayed width - may be smaller than duration as not all prog may be displayed

	this._display_mins = this.calc_display_mins() ;
	width = this._display_mins * Prog.settings.PX_PER_MIN ;

	var li = document.createElement("li");
	li.style.width = width+"px" ; 
	li.className = "vevent" ; 

	// create the program content - keep track of this for when we change the record settings etc
	this.dom_content = this._create_content() ;

	// add content to wrapper
	li.appendChild(this.dom_content);

	// add wrapper to parent			
	node.appendChild(li) ;

	// save node for later - ???? May not work if going into doc frag ????
	this.dom_node = li ;

Profile.stop("Prog.display") ;
	
	return li ;
}

/*------------------------------------------------------------------------------------------------------*/
// Calculate how many minutes of this program are actually on display
Prog.prototype.calc_display_mins = function()
{

	var display_mins = this.duration_mins ;
	if (this.start_mins < Prog.settings.DISPLAY_START_MINS)
	{
		display_mins -= (Prog.settings.DISPLAY_START_MINS - this.start_mins) ;
	}
	if (this.end_mins > Prog.settings.DISPLAY_END_MINS)
	{
		display_mins -= (this.end_mins - Prog.settings.DISPLAY_END_MINS) ;
	}
	if (display_mins < 0) display_mins=0;

	return display_mins ;
}

/*------------------------------------------------------------------------------------------------------*/
// Create the program content in a new 'a' element & return the 'a' element when we're done
Prog.prototype._create_content = function()
{
	// nasty magic number (difference between li width and the span widths
	var width = (this._display_mins * Prog.settings.PX_PER_MIN)-9 ;

//debug
if (width <= 0)
{
	width=1;
}

	var a = document.createElement("a");
	var class_name = "url uid" ;	// NOTE: Do *NOT* use variable name 'class' - IE fails!
	if (this.record > 0)
	{
		class_name += " record" ;
		if (this.hasOnlyIPLAY())
		{
			class_name += " iplay" ;
		}
	}
	a.className = class_name ; 
	
	// add a popup display to show program details
	this.add_prog_popup(a) ;

		var span_wrap = document.createElement("span");
		span_wrap.className = "wrap" ; 
		span_wrap.style.width = width+"px" ; 
		a.appendChild(span_wrap);

			var span_summ = document.createElement("span");
			span_summ.className = "summary" ; 
			span_summ.style.width = width+"px" ; 
			span_summ.appendChild(document.createTextNode(this.title));
			span_wrap.appendChild(span_summ);

			if (this.record > 0)
			{				
				var span_rec = document.createElement("span");
					var img = document.createElement("img");
					img.src = Prog.RecImg(this.record) ;
					span_rec.appendChild(img) ; 
					
				span_wrap.appendChild(span_rec);

// TODO: Need to pass prog priority up (undef at the moment!)
//
//				span_rec = document.createElement("span");
//					img = document.createElement("img");
//					img.src = Prog.PriImg(Prog.priIndex(this.priority)) ;
//					span_rec.appendChild(img) ; 
//					
//				span_wrap.appendChild(span_rec);
			}
			
			//	<span class="category">
			//		<span class="Film">
			//			<img src="listings-record_files/icon_film.gif">
			//		</span>
			//		Film
			//	</span>

			var span_cat = document.createElement("span");
			span_cat.style.width = width+"px" ; 
			span_cat.className = "category" ; 

				var span_genre = document.createElement("span");
				span_genre.className = this.genre ; 
				span_cat.appendChild(span_genre);

				if (this.film)
				{
					var img = document.createElement("img");
					img.src = Prog.IconImg('icon_film') ;
					span_genre.appendChild(img) ; 
				}
			
			span_cat.appendChild(document.createTextNode(this.genre));
			span_wrap.appendChild(span_cat);

	return a ;
}

///////////////////////////////////////////////////////////////////////////////////

// work out reverse map
for (var i in Prog.PROG_MAP)
{
	var field = Prog.PROG_MAP[i] ;
	Prog.PROG_FIELDS[field] = i ;
}
	
