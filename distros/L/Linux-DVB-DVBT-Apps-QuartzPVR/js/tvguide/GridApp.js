/*
Application for a tvguide grid display

VERSION 1.001


GridApp object manages the sub-objects used to store listings data (and displaying the data), along with
communicating with the server PHP script via Ajax commands (where the response is formatted as JSON and converted
into objects)

Hierarchy
---------

	GridApp
		Grid						- EPG shown in a timeline grid format (time horizontally; channels vertically)
			Schedule				- Manages the PVR recording schedule (shown as timeline bars above the channels)
			Chans					- Manages a single channel (i.e. a row in the grid)
				Recording			- Wraps up a Prog with recording (or not) info
					Prog			- A single program
		RecList						- Recording list: requested recordings & actual scheduled program recordings shown as a table
			Recording				- Wraps up a Prog with recording (or not) info (Amended for RecList)
				Prog				- A single program (Amended for RecList)
		

Settings
--------

Settings are sent from the PHP as a settings object that initialises GridApp. GridApp then passes this information
down the hierarchy (i.e. it passes this to Grid & RecList, which in turn pass the settings down to their sub-objects)

AJAX
----




*/


var GridApp = {
		
	// Pages
	grids 		: {
		"tv"		: new Grid(),
		"radio"		: new Grid()
	},
	grid		: null,					// currently displayed grid
	recList		: new RecList(),		// requested recordings list
	srchList	: new SearchList(),		// search programs list
	recorded	: new Recorded(),		// recorded programs page
	chanSel		: new ChanSel(),		// channel select page
	scan		: new Scan(),			// channel scan page
	
	currentPage	: '',
	
	// Other data
	types		: {
		"tv"		: {
			display		: "TV",
			other		: "radio"		// what to switch to when "clicked"
		},
		"radio"		: {
			display		: "Radio",
			other		: "tv"			// what to switch to when "clicked"
		}
	},
	url			: null,
	loading		: null,
	cmdCache	: null,				
	settings	: {},
	msgbox		: null,
	timestamp	: 1,
	debug		: 1,
	getFlag		: 0,
	redrawFlag	: 0,
	allChans 	: {},		// Map chanid to channel object for ALL channels TV or Radio
	allChansList: new SortedObjList('chanid', Chan.chanidSort),		// List of all channels, sorted by channel id
	
	// List of registered objects that need to be called when page changes
	pageChange	: [],
	
	// Image cache
	imageDir	: '',
	ImageCache  : {}
} ;

GridApp.IMAGES = [
       'plus',
       'minus',
       'grid'
] ;

//--------------------------------------------------------------------------------------------
GridApp.init = function()
{
try {

	log.options.timestamp=1;
	Profile.start('GridApp.init') ;
	
	var today = new Date() ;
	var date = DateUtils.date(today) ;
	var hour = today.getHours() ;
	
	// Init setting
	Settings.setApp(GridApp) ;
	
	// Set up image location
	GridApp.imageDir = Settings.imagePath(); 
	
	// Loading is the one and only GIF (for animation)
	GridApp.loading = new Loading(GridApp.imageDir+"/loading.gif") ;
	
	// Setup
	GridApp.setup({
		DISPLAY_DATE: date, 
		DISPLAY_HOUR: hour, 
		DISPLAY_CHANIDX: 0,		// this is just the index in the local array (nothing to do with channel name, channel id etc)
		NUM_PVRS: 1,
		PVRS: [{adapter:'0', name:''}],
		LISTINGS_TYPE: "tv",
		SHOW_PVR: Settings.cookie.showPvr,
		PROG_POPUP: Settings.cookie.progPopup,
		DISPLAY_PERIOD: Settings.cookie.period
	}) ;
	
	GridApp.msgbox = new Msgbox() ;

	// Create a timestamp for AJAX cache avoidance
	GridApp.timestamp = today.valueOf() ;
	
	// log.debug("location", location);
	
	// Get grid to clear out any default HTML
	Grid.clear_grid() ;

	// Get data
	GridApp.get('init', {});	

	Profile.stop('GridApp.init') ;

}
catch(e) {
	GridApp.error_handler("Blast! ", e) ;
};	

} 

//--------------------------------------------------------------------------------------------
// Causes re-setup and re-display of current page - used for window resize
GridApp.redraw = function()
{
	// recalc environment
	Env.screenSize() ;

log.debug("GridApp.redraw() getFlag="+GridApp.getFlag+", redrawFlag="+GridApp.redrawFlag) ;

	// re-calcs screen size
	GridApp.setup({
		SHOW_PVR: Settings.cookie.showPvr,
		PROG_POPUP: Settings.cookie.progPopup,
		DISPLAY_PERIOD: Settings.cookie.period
	}) ;

	// Get data
	if (!GridApp.getFlag)
	{
		// reload last (cacheable) command (==page)
		if (!GridApp.cmdCache)
		{
			GridApp.cmdCache = {
				cmd		: 'init',
				options	: {}
			} ;
		}
		
		GridApp.get(GridApp.cmdCache.cmd, GridApp.cmdCache.options);
		GridApp.redrawFlag = 0 ;
	}
	else
	{
		// schedule a redraw
		GridApp.redrawFlag = 1 ;
	}
log.debug("GridApp.redraw()-DONE getFlag="+GridApp.getFlag+", redrawFlag="+GridApp.redrawFlag) ;
	
}

//--------------------------------------------------------------------------------------------
GridApp.setup = function(settings)
{
	Profile.start('GridApp.setup') ;

	for (var setting in settings)
	{
		GridApp.settings[setting] = settings[setting] ;
	}
	
	// Create a useful lookup to convert from PVR adapter to the PVR list index
	GridApp.settings['PVR_LOOKUP'] = {} ;
	for (var i=0, len=GridApp.settings['PVRS'].length; i < len; i++)
	{
		var adapter = GridApp.settings['PVRS'][i].adapter ;
		GridApp.settings['PVR_LOOKUP'][adapter] = i ;
	}
	

	// Update useful date info
	var dt = DateUtils.datetime2date(GridApp.settings.DISPLAY_DATE, GridApp.settings.DISPLAY_HOUR+':00') ;
	GridApp.settings.DISPLAY_DATE_INFO = {
		DT 			: dt,
		DAYNUM		: dt.getDay(),
		DAYNAME		: DateUtils.dayname(dt),
		DAY			: dt.getDate()
	} ;
	
	// Screen size
	GridApp.settings.SCREEN_WIDTH = screen.width ;
	GridApp.settings.HALF_SCREEN_WIDTH = GridApp.settings.SCREEN_WIDTH / 2 ;
	GridApp.settings.SCREEN_HEIGHT = screen.height ;
	GridApp.settings.HALF_SCREEN_HEIGHT = GridApp.settings.SCREEN_HEIGHT / 2 ;

	GridApp.settings.TOTAL_PAD = 10 ;
	if (Env.BROWSER.PS3)
	{
		// For PS3 - fill the screen
		GridApp.settings.GRID_WIDTH = Env.SCREEN_WIDTH-GridApp.settings.TOTAL_PAD ;
	}
	else
	{
		// For everything else, use 98%
		GridApp.settings.GRID_WIDTH = parseInt(Env.SCREEN_WIDTH * 0.98) ;
	}
	GridApp.settings.GRID_HEIGHT = Env.SCREEN_HEIGHT ;
	GridApp.settings.TOTAL_HEIGHT = Env.SCREEN_HEIGHT ;
	
	GridApp.settings.TOTAL_WIDTH = GridApp.settings.GRID_WIDTH + GridApp.settings.TOTAL_PAD ;
	GridApp.settings.TOTAL_PX = GridApp.settings.TOTAL_WIDTH ;

	
	// Popup size
	GridApp.settings.POPUP_WIDTH_PX = 300 ;

	// Font - TODO - calc based on browser, screen size etc
	GridApp.settings.FONT_SIZE = 21 ;
	
	
	
	// Set images
	GridApp.cacheImages() ;
	
	
	//-------------------------------------------------------------------------------
	// Pass settings down to display objects
	var grid_settings = {} ;
	for (var setting in GridApp.settings)
	{
		grid_settings[setting] = GridApp.settings[setting] ;
	}

	// extra info
	grid_settings['debug'] = GridApp.debug ;
	grid_settings['app'] = GridApp ;
	grid_settings['http_get'] = function(obj, options) { GridApp.get(obj, options); } ;

	
	//-------------------------------------------------------------------------------
	// Pages
	
	// Setup Grid
	Grid.setup(grid_settings) ;
	
	// Setup RecList
	RecList.setup(grid_settings) ;
	
	// Setup SearchList
	SearchList.setup(grid_settings) ;
	
	// Setup Recorded
	Recorded.setup(grid_settings) ;
	
	// Setup ChanSel
	ChanSel.setup(grid_settings) ;
	
	// Setup Scan
	Scan.setup(grid_settings) ;
	
	
	
	// Setup TitleBar
	TitleBar.setup(grid_settings) ;
	
	
	Profile.stop('GridApp.setup') ;
}


/*------------------------------------------------------------------------------------------------------*/
//Return image path for this name
GridApp.imgPath = function (name)
{
	return GridApp.imageDir + "/"+name+".png" ;
}

/*------------------------------------------------------------------------------------------------------*/
// Return the image src (and cache any uncached image)
GridApp.getImage = function (name)
{
	if (!GridApp.ImageCache[name])
	{
		GridApp.ImageCache[name] = new Image() ;
		GridApp.ImageCache[name].src = GridApp.imgPath(name) ;
	}
	return GridApp.ImageCache[name].src ;
}


/*------------------------------------------------------------------------------------------------------*/
// Cache images
GridApp.cacheImages = function ()
{
	for (var i in GridApp.IMAGES)
	{
		var name = GridApp.IMAGES[i] ;
		GridApp.getImage(name) ;
	}
}


//=============================================================================================
// AJAX
//=============================================================================================

//--------------------------------------------------------------------------------------------
GridApp.checkUrl = function(url)
{
	if (!GridApp.url)
	{
		GridApp.url = location.protocol + '//' + location.host + location.pathname ;
	}
}


//== Channel Select ==

/*------------------------------------------------------------------------------------------------------*/
//Get channels
GridApp.showChanSel = function()
{
	GridApp.get("chanSel") ;
}


/*------------------------------------------------------------------------------------------------------*/
//Set displayed channels
GridApp.setChanSel = function(chanSelEntry)
{
	var params = {
		chanid:		chanSelEntry.chanid,
		show:		chanSelEntry.show
	} ;

	GridApp.get("chanSelSet", {
		parameters : params
	}) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Get channels
GridApp.updateChanSel = function()
{
	GridApp.get("chanSelUp", {
		nocache		: 1
	}) ;
}

//== Scan ==

/*------------------------------------------------------------------------------------------------------*/
//Show scan status
GridApp.showScan = function()
{
	// don't show the "loading.." animation for scan updates
	var showLoading = 1 ;
	if (GridApp.currentPage == "scan")
	{
		// already on this page, so don't show loading animation
		showLoading = 0 ;
	}
	
	GridApp.get("scanInfo", {
		showLoading		: showLoading
	}) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Start scanning
GridApp.startScan = function(settings)
{
	var params = $.extend(
		{
			file	 	: '',
			clean		: 0,
			adpater		: ''
		},
		settings || {}
	) ;

	GridApp.get("scanStart", {
		nocache		: 1,
		parameters 	: params
	}) ;
}



//== Recorded ==

/*------------------------------------------------------------------------------------------------------*/
//Get recorded programs
GridApp.showRecorded = function()
{
	GridApp.get("recorded") ;
}



//== RecList ==

/*------------------------------------------------------------------------------------------------------*/
//Get recordings list
GridApp.showRecordings = function()
{
	GridApp.get("recList") ;
}

/*------------------------------------------------------------------------------------------------------*/
// Change recordings list - always goes from record>0 to record>=0
GridApp.setRecordings = function(prog)
{
	var recspec = GridApp.recspec(prog) ;
	
	GridApp.get('recListRec', {
		nocache		: 1,
		parameters : {
			rec : recspec
		}
	}) ;
		
}

//== SearchList ==

/*------------------------------------------------------------------------------------------------------*/
//Get recordings list
GridApp.showSearch = function(searchObj)
{
	searchObj = SearchList.initSearch(searchObj) ;
	var params = SearchList.copySearch(searchObj, {}) ;

	GridApp.get("srchList", {
		parameters : params
	}) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Change the recording level on one of the searched programs. Should return to the same search results
//
GridApp.setSearchRec = function(prog, searchObj)
{
	var recspec = GridApp.recspec(prog) ;
	
	// log.debug("GridApp.setSearchRec(recspec="+recspec) ;

	var params = {
			rec : recspec
		} ;
	searchObj = SearchList.initSearch(searchObj) ;
	SearchList.copySearch(searchObj, params) ;
	
	GridApp.get('srchListRec', {
		nocache		: 1,
		parameters 	: params
	}) ;
}

/*------------------------------------------------------------------------------------------------------*/
// Create a new fuzzy recording
//
GridApp.setFuzzySearchRec = function(prog, searchObj)
{
	var recspec = GridApp.recspec(prog) ;
	
	// log.debug("GridApp.setFuzzySearchRec(recspec="+recspec) ;

	var params = {
			rec : recspec
		} ;
	searchObj = SearchList.initSearch(searchObj) ;
	SearchList.copySearch(searchObj, params) ;
	
	GridApp.get('srchListFuzzyRec', {
		nocache		: 1,
		parameters 	: params
	}) ;
}


//== Grid ==

/*------------------------------------------------------------------------------------------------------*/
//Get grid
GridApp.showGrid = function()
{
	GridApp.get("update") ;
}

//--------------------------------------------------------------------------------------------
GridApp.set_hour = function(hour)
{
	GridApp.setup({
		DISPLAY_HOUR: hour
	}) ;

	GridApp.get('update', {}) ;
}

//--------------------------------------------------------------------------------------------
GridApp.set_date = function(dt)
{
	GridApp.setup({
		DISPLAY_DATE: DateUtils.date(dt)
	}) ;

	GridApp.get('update', {}) ;
}

//--------------------------------------------------------------------------------------------
GridApp.set_rec = function(prog, old_record)
{
try {
	prog.rid = 0 ;
	if (old_record > 0)
	{
		// get existing record id
		var recording = GridApp.grid.lookup_recording(prog.pid) ;
		prog.rid = recording.rid ;
	}
	var recspec = GridApp.recspec(prog) ;
	
	GridApp.get('rec', {
		nocache		: 1,
		parameters 	: {
			rec : recspec
		}
	}) ;
	
}
catch (e) {
	log.error("Bugger! Failed to set record "+e) ;
	
	GridApp.error_handler("Failed to set recording: "+e) ;
}

}

//== common ==

//--------------------------------------------------------------------------------------------
GridApp.get = function(cmd, options)
{
//	GridApp.loading.show() ;
	var showLoading = 1 ;
	if (options && options.hasOwnProperty('showLoading'))
		showLoading = options.showLoading ;
	
	if (GridApp.getting(showLoading))
	{
		// don't run if alrwady running
		return ;
	}
	
	Profile.start('GridApp.get') ;

	GridApp.checkUrl() ;

	var params = {} ;
	if (options && options.parameters)
		params = options.parameters ;
	
	// Track each command (unless told not to) so we can reload on redraw
	if (!(options && options.nocache))
	{
		// check to see if popups should be closed
		if (!GridApp.cmdCache || (GridApp.cmdCache.cmd !== cmd))
		{
			// new command so close any open popups
			ClickHandler.closeAll() ;
			InPlace.closeAll() ;
		}
		
		// Update the cache
		GridApp.cmdCache = {
			cmd		: cmd,
			options	: options
		} ;
	}

	params['json'] = cmd ;
//	params['ts'] = ++GridApp.timestamp ; // Change timestamp each time to avoid caching

	if (!params['hr'])
		params['hr'] = GridApp.settings.DISPLAY_HOUR ;
	if (!params['dt'])
		params['dt'] = GridApp.settings.DISPLAY_DATE ;
	if (!params['t'])
		params['t'] = GridApp.settings.LISTINGS_TYPE ;
	if (!params['shw'])
		params['shw'] = GridApp.settings.DISPLAY_PERIOD ;

	HTTP.get(GridApp.url, function(reply) {GridApp.http_reply_handler(reply); }, 
		{
			timeout		: 30000,
			parameters	: params,
			errorHandler	: function(xhr, status, e) { GridApp.error_handler("HTTP error :"+status+" : "+e); },
			timeoutHandler	: function() { GridApp.error_handler("HTTP timeout"); },
			progressHandler	: function() { /* log.debug("HTTP progress"); */ }
		}) ;
}

//--------------------------------------------------------------------------------------------
GridApp.http_reply_handler = function(reply)
{
//log.debug("GridApp.http_reply_handler() getFlag="+GridApp.getFlag+", redrawFlag="+GridApp.redrawFlag) ;

	
try {
	if (GridApp.debug >= 5)
	{
		// log.debug("HTTP reply", reply) ;
	}
	Profile.stop('GridApp.get') ;
	Profile.start('GridApp.http_reply_handler') ;

	
	var msgType ;
	var msgContent ;
	
	if (reply && reply.cmd)
	{
		var displayPage = null ;
		var redisplay_schedule = [] ;
		
		// tv/radio
		var listingsType = GridApp.settings.LISTINGS_TYPE ;
		
		// log.debug(reply.cmd+" cmd") ;
		
		// Let the grid do the processing
		if (reply.data)
		{
			// log.debug(" + got data") ;
			if (reply.data.settings)
			{
				GridApp.setup(reply.data.settings) ;
				displayPage = "grid" ;
				listingsType = GridApp.settings.LISTINGS_TYPE ;
			}
			

			if (reply.data.chans)
			{
				for (var listType in GridApp.grids)
				{
					var grid = GridApp.grids[listType] ; 
					if (reply.data.chans.hasOwnProperty(listType))
					{
						grid.update_chans(reply.data.chans[listType]) ;
						displayPage = "grid" ;
						
						// keep a list of all channels
						var chans = grid.channels.values() ;
						for (var i=0, len=chans.length; i < len; i++)
						{
							var chan = chans[i] ;
							GridApp.allChans[chan.chanid] = chan ;
							GridApp.allChansList.add(chan) ;
						}
					}
				}
			}

			if (reply.data.progs)
			{
				// NOTE: Prog data contains a 'record' field but this is a dummy and is always 0
				// log.debug(" + + update progs") ;
				GridApp.grids[listingsType].update_progs(reply.data.progs) ;
				displayPage = "grid" ;
			}
			
			if (reply.data.recList)
			{
				// log.debug(" + + update list") ;
				GridApp.recList.update(reply.data.recList) ;
				displayPage = "recList" ;
			}
			
			if (reply.data.srchList)
			{
				GridApp.srchList.update(reply.data.srchList) ;
				displayPage = "srchList" ;
			}
			if (reply.data.srchSettings)
			{
				GridApp.srchList.update_search(reply.data.srchSettings) ;
				displayPage = "srchList" ;
			}
			
			if (reply.data.recorded)
			{
				GridApp.recorded.update(reply.data.recorded) ;
				displayPage = "recorded" ;
			}
			
			if (reply.data.chanSel)
			{
				GridApp.chanSel.update(reply.data.chanSel) ;
				displayPage = "chanSel" ;
			}
			
			if (reply.data.scan)
			{
				GridApp.scan.update(reply.data.scan) ;
				displayPage = "scan" ;
			}
			
			
			if (reply.data.schedule)
			{
				var multirec = [] ;
				var iplay = [] ;
				if (reply.data.multirec)
				{
					multirec = reply.data.multirec ;
				}
				if (reply.data.iplay)
				{
					iplay = reply.data.iplay ;
				}
				
				// log.debug(" + + update schedule") ;
				redisplay_schedule = GridApp.grids[listingsType].update_schedule(
						reply.data.schedule, 
						multirec,
						iplay
				) ;
			}
			
			if (reply.data.message)
			{
				msgType = "msg" ;
				if (reply.data.message.type)
				{
					if (reply.data.message.type in GridApp.msgbox)
					{
						msgType = reply.data.message.type ;
					}
				}
				// log.debug(" + + message: "+msgType) ;
				
				msgContent = reply.data.message.content ;
			}
			
		}
	
		// Update current grid
		GridApp.grid = GridApp.grids[listingsType] ;

		// Display
		if (displayPage)
		{
			GridApp.currentPage = displayPage ;
			GridApp[displayPage].display() ;
		}
		else
		{
			// not doing a full blown screen display so see if we need to re-display due to schedule update
			if (redisplay_schedule.length > 0)
			{
				// re-display any progs 
				GridApp.grid.redisplay_progs(redisplay_schedule) ;
			}
		}
		
		Profile.show_results() ; 
		Profile.clear_results() ; 
		
		if (msgType && msgContent)
		{
			// display appropriate message type
			GridApp.msgbox[msgType](msgContent) ;
		}
			
	}
	else
	{
		GridApp.error_handler("Invalid http reply: "+reply) ;
	}
	Profile.stop('GridApp.http_reply_handler') ;
}
catch(e) {
	GridApp.error_handler("HTTP Error:", e) ;
};

	GridApp.notGetting() ;
	
	//-------------------------------------------------------------
	// Redraw check
	if (GridApp.redrawFlag)
	{
		GridApp.redraw() ;
	}

//log.debug("GridApp.http_reply_handler()-DONE getFlag="+GridApp.getFlag+", redrawFlag="+GridApp.redrawFlag) ;
	
} 

//--------------------------------------------------------------------------------------------
GridApp.getting = function(showLoading)
{
	var alreadyGetting = 1 ;
	
	// check to see if we're already getting
	if (!GridApp.getFlag)
	{
		// start new get
		if (showLoading)
		{
			GridApp.loading.show() ;
		}
		alreadyGetting = 0 ;
		GridApp.getFlag = 1 ;
	}
	
	return alreadyGetting ;
}

//--------------------------------------------------------------------------------------------
GridApp.notGetting = function()
{
	// start new get
	GridApp.loading.hide() ;
	GridApp.getFlag = 0 ;
}

//=============================================================================================
// ERROR
//=============================================================================================

//--------------------------------------------------------------------------------------------
GridApp.error_handler = function(msg, error)
{
	log.error(msg) ;

	// hide "loading" display if running
	GridApp.notGetting() ;

	// show dialog..
	if (GridApp.msgbox)
	{
		var content = [msg] ;
		
		if (typeof error == "object")
		{
			if ("name" in error)
			{
				content.push(error.name) ;
			}
			if ("message" in error)
			{
				content.push(error.message) ;
			}
			if ("fileName" in error)
			{
				content.push("File: "+error.fileName) ;
			}
			if ("lineNumber" in error)
			{
				content.push("Line: "+error.lineNumber) ;
			}
			
/////////////////////////////////////////
		    // Get property names of the object and sort them alphabetically
		    var names = [];
		    for(var name in error) names.push(name);
		    names.sort();

		    // Now loop through those properties
			content.push("Error Object:") ;
		    for(var i = 0; i < names.length; i++) {
		        var name, value, type;
		        name = names[i];
		        try {
		            value = error[name];
		            type = typeof value;
		        }
		        catch(e) { // This should not happen, but it can in Firefox
		            value = "<unknown value>";
		            type = "unknown";
		        };
		        
		        if (type == "object" || type == "function" || type == "unknown") continue ;
		        
		        content.push(" + "+name+" = "+value) ;
		    }
/////////////////////////////////////////			
			
		}
		
		// show message box
		GridApp.msgbox.error(content) ;
	}

}


//=============================================================================================
// UTILITY
//=============================================================================================

// Map from Prog data into a recspec
GridApp.RECMAP = {
	'pid'		: 'pid',
	'record'	: 'rec',
	'rid'		: 'rid',
	'priority'	: 'pri',
	'pathspec'	: 'pth',
	'tva_series': 'ser'
} ;

GridApp.FUZZY_RECMAP = {
		'title'		: 'tit',
		'channel'	: 'ch'
	} ;

//--------------------------------------------------------------------------------------------
GridApp.recspec = function(prog)
{
	var recspec = "" ;
	for (var field in GridApp.RECMAP)
	{
		if (prog.hasOwnProperty(field) && (prog[field] !== null))
		{
			var v = GridApp.RECMAP[field] ;
			var val = prog[field] ;
			recspec += v+":"+val+":" ;
		}
	}
	
	// add extra fields if fuzzy record
	if (Prog.isFuzzy(prog.record))
	{
		for (var field in GridApp.FUZZY_RECMAP)
		{
			if (prog.hasOwnProperty(field) && (prog[field] !== null))
			{
				var v = GridApp.FUZZY_RECMAP[field] ;
				var val = prog[field] ;
				recspec += v+":"+val+":" ;
			}
		}
	}
	
	return recspec ;
}

//--------------------------------------------------------------------------------------------
// Set the channel number to start displaying from then redisplay
GridApp.set_chanidx = function(idx)
{
	GridApp.setup({
		DISPLAY_CHANIDX: idx
	}) ;

	GridApp.grid.display() ;
}



//--------------------------------------------------------------------------------------------
GridApp.create_handler = function(handler, arg)
{
	// Wrap up arg to be passed to handler, throw away event
	return function() { handler(arg) } ;
}



//=============================================================================================
// Register init routine when doc loaded
$( function() {
	
	// set up the window resize handler
	// Do NOT do this for Android - keeps getting the resize event
//	if (!Env.BROWSER.Android)

	if (navigator.userAgent.search(/Android/i) < 0)
	{
			$(window).resize(GridApp.redraw) ; 
	}
	
	// Init application
	GridApp.init() ;
} ) ;

