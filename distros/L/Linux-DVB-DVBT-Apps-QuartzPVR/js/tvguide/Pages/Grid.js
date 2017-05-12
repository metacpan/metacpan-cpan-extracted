/*
Manages all of the channels for a tvguide grid display

*/

/*------------------------------------------------------------------------------------------------------*/
// Constructor
function Grid()
{
//TODO: fix channel name <=> chan id mapping (or just go via chanid everywhere?)...
// e.g. BBC1 is either "BBC 1" or "BBC ONE"

	// hash of chanid : channel name
	this.chan_list = {} ;
	
	// hash of channel name : chanid
	this.chan_map = {} ;
	
	// Actual list of channels (indexed by chanid; sorted by chanid)
	this.channels = new SortedObjList("chanid", function(a,b) {return a.chanid - b.chanid;} ) ;
	
	// Recording schedule list - one list per pvr, used for schedule display
	this.schedule_list = [] ;
	
	// Complete recording schedule, indexed by program id, used to lookup recording from pid
	this.complete_schedule = {} ;
	
	// Keep track of various dom elements
	this.dom = {
		gridbox 	: null,
		schedule	: []
	} ;
	
	
}

//Set to true to globally enable debugging
Grid.prototype.logDebug = 1 ;


/*------------------------------------------------------------------------------------------------------*/
// Convert channel id to channel name
//
Grid.prototype.lookup_chan = function(chanid)
{
	return this.chan_list[chanid] ;
}

/*------------------------------------------------------------------------------------------------------*/
// Convert prog id to Recording
//
Grid.prototype.lookup_recording = function(pid)
{
	return this.complete_schedule[pid] ;
}

/*------------------------------------------------------------------------------------------------------*/
//Add/Create channels
//
//chans_data is a HASH of the form:
//
//chan_id : [ chanid, "chan name", show, canIPLAY ]
//	0	: "chanid", 
//	1	: "name", 
//	2	: "show", 
//	3	: "iplay",
//	4	: "type",
//	5	: "display",
//
Grid.prototype.update_chans = function(chans_data)
{
	Profile.start('Grid.update_chans') ;

	// Create channel objects
	for (var chanid in chans_data)
	{
		var chanEntry = chans_data[chanid] ;

		var chanName = chanEntry[1] ;
		var show = chanEntry[2] ;		// user wants this channel to be displayed
		var chanIplay = chanEntry[3] ;
		var type = chanEntry[4] ;
		
		// see if already created
		if (!this.chan_list[chanid])
		{
			// new
			this.chan_list[chanid] = chanName ;
			this.channels.add(new Chan(chanid, chanName, chanIplay, show, type)) ;
			
			// reverse lookup
			this.chan_map[chanName] = chanid ;
		}
		else
		{
			// Update settings
			this.chan_list[chanid] = chanName ;
			this.chan_map[chanName] = chanid ;

			chan = this.channels.get(chanid) ;
			chan.show = parseInt(show, 0) ;
		}
	}

	Profile.stop('Grid.update_chans') ;
}

/*------------------------------------------------------------------------------------------------------*/
// Add/Create progs
//
// progs_data is a HASH of the form:
//
// chan_id : [ array of progs ]
//
Grid.prototype.update_progs = function(progs_data)
{
	Profile.start('Grid.update_progs') ;

	// Create channel objects
	for (var chanid in progs_data)
	{
// log.dbg(this.logDebug>=2, "update_progs() chan="+chanid) ;
		// see if already created
		if (!this.chan_list[chanid])
		{
			log.error("Channel "+chanid+" not previously defined", progs_data[chanid]) ;
		}
		else
		{
			// get the channel to handle progs
			var chan = this.channels.get(chanid) ;
// log.dbg(this.logDebug>=2, "calling chan update_progs()") ;
			chan.update_progs(progs_data[chanid]) ;
		}
	}

	Profile.stop('Grid.update_progs') ;
}

/*------------------------------------------------------------------------------------------------------*/
// Re-display any progs that are on display
//
// progs_list is an ARRAY of progs
//
Grid.prototype.redisplay_progs = function(progs_list)
{
	Profile.start('Grid.redisplay_progs') ;

	// update the programs
	for (var i=0; i < progs_list.length; ++i)
	{
		// Get the prog to sort itself out
		progs_list[i].redisplay() ;
	}

	// update the recording schedule
	var gridbox = this.dom['gridbox'] ;
	if (Grid.settings.SHOW_PVR)
	{
		for (var pvr_index=0; pvr_index < this.schedule_list.length; ++pvr_index)
		{
			var schedule = this.schedule_list[pvr_index].display() ;
			var prev_schedule = this.dom['schedule'][pvr_index] ;
			
			if (prev_schedule)
			{
				gridbox.replaceChild(schedule, prev_schedule) ;
			}
			else
			{
				gridbox.appendChild(schedule) ;
			}
	
			this.dom['schedule'][pvr_index] = schedule ;
		}
	}

	Profile.stop('Grid.redisplay_progs') ;
}

/*------------------------------------------------------------------------------------------------------*/
// Update the recording schedule
//
// NOTE: This is guaranteed to be called AFTER getting the full Progs information
//
// NOTE2: This routine sets the Prog's .record and .pvr fields
//
//schedule_data is an ARRAY of ARRAYS, each ARRAY is the form:
//
//   0            1             2               3               4		5				6
// [ <record id>, <program id>, <channel id>, <record level>, <pvr>, <multiplex id>, <multiplex prog type> ]
//
// When called with iplay schedule data, each array is of the form:
//
//   0            1             2               3           
// [ <record id>, <program id>, <channel id>, <record level> ]
//
// 
// multirec_data is an ARRAY of ARRAYS, each ARRAY is the form:
//
//#	0	: "multid", 
//#	1	: "start_time", 
//#	2	: "start_date", 
//#	3	: "end_time", 
//#	4	: "end_date", 
//#	5	: "duration_mins", 
//#	6	: "adapter"
//
//
// NOTE: No display changes are done here, just works out what needs to be updated
//
Grid.prototype.update_schedule = function(schedule_data, multirec_data, iplay_data)
{
	Profile.start('Grid.update_schedule') ;

	// log.dbg(this.logDebug, "Grid.update_schedule()") ;
	
	var affected_progs = {} ;
	var redisplay = false ;
	
	// Ensure we've got the correct number of recording schedule lists
	if (this.schedule_list.length != Grid.settings.NUM_PVRS)
	{
		if (this.schedule_list.length > Grid.settings.NUM_PVRS)
		{
			// delete
			for (var i=this.schedule_list.length-1; i >= Grid.settings.NUM_PVRS; --i)
			{
				delete this.schedule_list[i] ;
			}
		}
		else
		{
			// create
			for (var i=this.schedule_list.length; i < Grid.settings.NUM_PVRS; ++i)
			{
				var adapter = Grid.settings.PVRS[i].adapter ;
				this.schedule_list[i] = new Schedule(adapter, Grid.settings) ;
			}
		}
	}

	// log.dbg(this.logDebug, "Grid.update_schedule() - empty schedule : num pvrs="+this.schedule_list.length) ;
	
	// Empty the schedules - create list of affected progs
	for (var pvr_index=0; pvr_index < this.schedule_list.length; ++pvr_index)
	{
if (!this.schedule_list.hasOwnProperty(pvr_index))
{
	var bugger=1 ;
}
		
		var recordings = this.schedule_list[pvr_index].values() ;
		this.schedule_list[pvr_index].empty() ;

		// log.dbg(this.logDebug, " * recordings["+pvr_index+"] = ", recordings) ;
		
		// clear prog and save in list
		for (var i=0; i < recordings.length; ++i)
		{
			var prog = recordings[i].prog ;
			// log.dbg(this.logDebug, " + prog = ", prog) ;
			
			// is this a Multirec?
			if (prog.type == 'Multirec')
			{
				for (var j=0; j < prog.progs.length; ++j)
				{
					var p = prog.progs[j] ;
					affected_progs[p.pid] = p ;
					p.record = 0 ;
					// log.dbg(this.logDebug, " + + multi prog = ", p) ;
				}
			}
			else
			{
				affected_progs[prog.pid] = prog ;
				prog.record = 0 ;
			}
			
			// remove from complete list
			delete this.complete_schedule[prog.pid] ;
		}		
	}
	
	// Need to handle any left-over progs (should only be IPLAY)
	for (var pid in this.complete_schedule)
	{
		var prog = this.complete_schedule[pid].prog ;
		affected_progs[pid] = prog ;
		
		// clear record level
		prog.record = 0 ;
		
		// remove from complete list
		delete this.complete_schedule[pid] ;
	}
	
	
	// clear out full list (should already be empty, but jsut in case)
	this.complete_schedule = {} ;
	
	
	// log.dbg(this.logDebug, "Grid.update_schedule() - process multirec") ;


	// Work through the multirec entries
	var multirec_list = [] ;
	for (var i=0; i < multirec_data.length; i++)
	{
		var entry = multirec_data[i] ;

		var multid = parseInt(entry[0], 10) ;
//		var pvr = parseInt(entry[6], 10) || 0 ;
		var adapter = entry[6] ;

		var multirec = new Multirec(entry) ;
		if (multirec)
		{
			multirec_list[multid] = multirec ;
			
			// Postpone adding to the schedule list until we know how many progs are in this multirec
			// The problem is that the Sql doesn't lend itself to quickly determining whether the multirec progs
			// are TV or Radio - and we don't want to show a multirec in the Radio listings if all it's progs
			// are TV
			
			// // Add to schedule list
			// var recording = this.schedule_list[pvr].add(0, 0, 0, multirec, multid) ;
			
			// Not required in complete list - this is not a real program and so can never have its
			// record level changed
			//	 this.complete_schedule[pid] = recording ;
		}
	}

	// log.dbg(this.logDebug, "Grid.update_schedule() - process progs") ;
	
	// Concat iplay information onto end of schedule
	if (iplay_data)
	{
		schedule_data = schedule_data.concat(iplay_data) ;
	}
	
	// Work through the entries
	for (var i=0; i < schedule_data.length; i++)
	{
		var entry = schedule_data[i] ;

		// see if we've got this channel/program
		var pid = entry[1] ;
		var chanid = parseInt(entry[2], 10) ;
		var chan = this.channels.get(chanid) ;
		if (chan)
		{
			// try getting prog
			var prog = chan.get_prog(pid) ;
			if (prog)
			{
				var rid = parseInt(entry[0], 10) ;
				var record = parseInt(entry[3], 10) ;
				
				var adapter = Grid.settings.PVRS[0].adapter ;
				var multid = 0 ;
				var type = 'p' ;

				// check for IPLAY entry
				if (entry.length <= 4)
				{
					// We only want to look at ilpay entries that do NOT have an associated DVBT
					// Since I've concat'd the 2 lists, just leave display to the DVBT record
					if (Prog.hasDVBT(record))
					{
						continue ;
					}
				}
				else
				{
					adapter = entry[4] ;
					multid = entry[5] ;
					type = entry[6] ;
				}
				
				var recording ;
				
				// Skip multiplex recordings
				if (type != 'mp')
				{
					if (Prog.hasOnlyIPLAY(record))
					{
						// IPLAY-only
						recording = new Recording(rid, chanid, record, prog, multid) ;
					}
					else
					{
						// Add to schedule list
						if (Grid.settings.PVR_LOOKUP.hasOwnProperty(adapter))
						{
							var pvr_index = Grid.settings.PVR_LOOKUP[adapter] ;
							recording = this.schedule_list[pvr_index].add(rid, chanid, record, prog, multid) ;
						}
					}
				}
				else
				{
					recording = multirec_list[multid].add_prog(rid, chanid, record, prog, multid) ;
				}

				// Add to full list - need this when user wants to change the record level for
				// a particular program
				//
				if (recording)
					this.complete_schedule[pid] = recording ;
				
				redisplay = true ;
				
				// update prog
				prog.pvr = adapter ;
				prog.record = record ;
				
				// add to list
				affected_progs[pid] = prog ;
			}
		}
	}

	// Now add multirec entries to the schedule list iff the multirec contains some programs
	for (var multid in multirec_list)
	{
		var multirec = multirec_list[multid] ;
		if (multirec.progs.length)
		{
			// Add to schedule list
			var adapter = multirec.pvr ;
			if (Grid.settings.PVR_LOOKUP.hasOwnProperty(adapter))
			{
				var pvr_index = Grid.settings.PVR_LOOKUP[adapter] ;
				var recording = this.schedule_list[pvr_index].add(0, 0, 0, multirec, multid) ;
			}
			
		}
	}

	
	
	// create a list
	var redisplay_schedule = [] ;
	for (var pid in affected_progs)
	{
		redisplay_schedule.push(affected_progs[pid]) ;
	}

	Profile.stop('Grid.update_schedule') ;
	
	return redisplay_schedule ;
}



/*
Grid.DAYS  = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] ;
*/

Grid.HOURS = ["12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11",
			  "12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"] ;

/*------------------------------------------------------------------------------------------------------*/
// Set the display windows
// start date & hour, display period in hours
//
//
//	DISPLAY_DATE: "2009-08-07", 
//	DISPLAY_HOUR: 12, 
//	DISPLAY_PERIOD: 3
//
//
Grid.setup = function(settings)
{
	if (!Grid.settings)
	{
		Grid.settings = {} ;
	}
	
	for (var setting in settings)
	{
		Grid.settings[setting] = settings[setting] ;
	}
	
	// Calc
	if (Grid.settings.DISPLAY_PERIOD < 2) Grid.settings.DISPLAY_PERIOD = 2 ; 
	Grid.settings.DISPLAY_TIME = Grid.settings.DISPLAY_HOUR + ":00" ;

	Grid.settings.DISPLAY_START_MINS = DateUtils.datetime2mins(Grid.settings.DISPLAY_DATE, Grid.settings.DISPLAY_TIME) ;
	Grid.settings.DISPLAY_END_MINS = Grid.settings.DISPLAY_START_MINS + Grid.settings.DISPLAY_PERIOD * 60 ;


/*

Structure:
	<body> #quartz-net-com
		<div> #quartz-body
			<div> #quartz-content
				<div> .chrome
					<div> #qtv-listings .listings
						<div> .hd
						<div> .bd #list-body
						<div> .ft
					
			
Layout is:

	<Heading> [in .hd]
	
	<Timebars:> [in .bd]
	[   Yesterday   ][ <Date>                                                                                       ][ Tomorrow  ]
	[   earlier     ][ <Time>           | <Time>           | <Time>           | <Time>           | <Time>           ][ later     ]
	
	<Recording Schedule:> [in .bd]
	[               ][                                                                                                           ]
	
	<Channels:> [in .bd]
	[ <Chan name>   ][ <Prog1>  | .......                                                                                        ]
	


Sizes:
									grid_width
	:<-------------------------------------------------------------------------------------------------------------------------->:
	[   Yesterday   ][ <Date>                                                                                          Tomorrow  ]
	[   earlier     ][ <Time>           | <Time>           | <Time>           | <Time>           | <Time>              later     ]
					 :<---------------->:
					      time_width
					 :<--------------------------------------------------------------------------------------------------------->:
					      total_time_width

	[ <Chan name>   ][ <Prog1>  | .......                                                                                        ]
	
	:<-------------->:
      chan_width
      
    :<------------>:
      chan_label_width

*/
// HDTV = 1920x1080

// log.dbg(this.logDebug, "Screen width="+Env.SCREEN_WIDTH)

//	Grid.settings.TOTAL_PAD = 10 ;
//	if (Env.BROWSER.PS3)
//	{
//
//// log.dbg(this.logDebug, " + set width for PS3") ;
//
//		// For PS3 - fill the screen
//		Grid.settings.GRID_WIDTH = Env.SCREEN_WIDTH-Grid.settings.TOTAL_PAD ;
//		
//		// show a screen full
//		Grid.settings.DISPLAY_CHANS = 8 ;
//		
//	}
//	else
//	{
//// log.dbg(this.logDebug, " + set 90% width") ;
//
////		// For everything else, use 90%
////		Grid.settings.GRID_WIDTH = parseInt(Env.SCREEN_WIDTH * 0.90) ;
//		// For everything else, use 98%
//		Grid.settings.GRID_WIDTH = parseInt(Env.SCREEN_WIDTH * 0.98) ;
//	}
//	Grid.settings.GRID_HEIGHT = Env.SCREEN_HEIGHT ;
//	
//	Grid.settings.TOTAL_WIDTH = Grid.settings.GRID_WIDTH + Grid.settings.TOTAL_PAD ;
//	Grid.settings.TOTAL_PX = Grid.settings.TOTAL_WIDTH ;
//
//	
//	// Popup size
//	Grid.settings.POPUP_WIDTH_PX = 300 ;
//
//	// Font - TODO - calc based on browser, screen size etc
//	Grid.settings.FONT_SIZE = 21 ;
//	
	
	// show all
	Grid.settings.DISPLAY_CHANS = 99 ;
	if (Env.BROWSER.PS3)
	{
		// show a screen full
		Grid.settings.DISPLAY_CHANS = 8 ;
	}
	
	// Calc px per minute based on displayed hours 
	Grid.settings.MIN_CHAN_WIDTH = 140 ;
	Grid.settings.PX_PER_MIN = parseInt( (Grid.settings.GRID_WIDTH-Grid.settings.MIN_CHAN_WIDTH) / (Grid.settings.DISPLAY_PERIOD * 60)) ; //-1 ; // allow for 1px border

	// Time bar & 1 hour's worth of program
	Grid.settings.TIME_WIDTH = Grid.settings.PX_PER_MIN * 60 ;
	Grid.settings.TIME_PX = Grid.settings.TIME_WIDTH - 1 ;	// allow for 1px border
	Grid.settings.TOTAL_TIME_WIDTH = Grid.settings.DISPLAY_PERIOD * Grid.settings.TIME_WIDTH ;
	Grid.settings.TOTAL_TIME_PX = Grid.settings.TOTAL_TIME_WIDTH - 1 ;
	
	
	// Channel name
	Grid.settings.CHAN_WIDTH = Grid.settings.GRID_WIDTH - Grid.settings.TOTAL_TIME_WIDTH ;
	Grid.settings.CHAN_PX = Grid.settings.CHAN_WIDTH ;


	// Time bar previous
	Grid.settings.TIME_PREV_PX = Grid.settings.CHAN_PX - 1 ; // 1px border
//	Grid.settings.TIME_PREV_LABEL_PX = Grid.settings.CHAN_PX - 9 ; // ??9??

	// Show day selector - split timebar into X days
	Grid.settings.DATE_LABEL_PX = 180 ; 
	Grid.settings.DAY_MARGIN_PX = 4 ;
	Grid.settings.DAY_NAV_PX = 16 ;
	Grid.settings.TOTAL_DAY_PX = Grid.settings.TOTAL_PX - Grid.settings.DATE_LABEL_PX ;
	// allow a bit of extra margin (4) so that everything fits on to the PS3 display
	Grid.settings.TOTAL_DAY_WIDTH = Grid.settings.GRID_WIDTH - Grid.settings.DATE_LABEL_PX -  2*(Grid.settings.DAY_NAV_PX+1+1+Grid.settings.DAY_MARGIN_PX) ;
	Grid.settings.DAY_WIDTH = parseInt( (Grid.settings.TOTAL_DAY_WIDTH - 4) / DateUtils.DAY_NAMES.length) ;
	Grid.settings.DAY_PX = Grid.settings.DAY_WIDTH - (2 * (Grid.settings.DAY_MARGIN_PX+1)) -1 ; // allow for 1px border 

// log.dbg(this.logDebug, "DAYS total="+Grid.settings.TOTAL_DAY_PX+", day width="+Grid.settings.DAY_WIDTH+", day px="+Grid.settings.DAY_PX) ;

	// Show hour selector - split timebar into X hours
	Grid.settings.HOUR_MARGIN_PX = 2 ;
	Grid.settings.HOUR_TOTAL_PX = Grid.settings.GRID_WIDTH ;
	Grid.settings.HOUR_WIDTH = parseInt(Grid.settings.HOUR_TOTAL_PX / Grid.HOURS.length) ;
	Grid.settings.HOUR_PX = Grid.settings.HOUR_WIDTH - (2 * (Grid.settings.HOUR_MARGIN_PX+1)) -1 ; // allow for 1px border 
	Grid.settings.HOUR_PREV_PX = parseInt( (Grid.settings.HOUR_TOTAL_PX - ( (Grid.settings.HOUR_WIDTH-1) * Grid.HOURS.length) ) / 2) ;

// log.dbg(this.logDebug, "Browser="+Env.browser+", PS3="+Env.BROWSER.PS3) ;
// log.dbg(this.logDebug, "Grid PX_PER_MIN="+Grid.settings.PX_PER_MIN) ;
// log.dbg(this.logDebug, "Grid GRID_WIDTH="+Grid.settings.HOUR_TOTAL_PX+"  HOUR_WIDTH="+Grid.settings.HOUR_WIDTH+" PREV="+Grid.settings.HOUR_PREV_PX) ;

	// send to programs
	Chan.setup(Grid.settings) ;
	
}

/*------------------------------------------------------------------------------------------------------*/
// Clear out the gridbox
Grid.clear_grid = function()
{
	var gridbox = document.getElementById("gridbox");
	gridbox.innerHTML = "" ;
}

/*------------------------------------------------------------------------------------------------------*/
// Get info for the other type of listings (e.g. switch from TV -> Radio)
Grid.prototype.switchListings = function(nextType)
{
	Grid.settings.app.get("init", {
		"parameters" : {
			't'	: nextType
		}
	}) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Display grid heading
Grid.prototype.display_head = function()
{
	var listingsType = Grid.settings.LISTINGS_TYPE ;
	var version = Grid.settings.PM_VERSION ;
	var dispCurrName = Grid.settings.app.types[listingsType].display ;
	var nextType = Grid.settings.app.types[listingsType].other ;
	
	TitleBar.display_head(
//		dispCurrName+" Listings (JQuery "+$.fn.jquery+")", 
		dispCurrName+" Listings (V "+version+")", 
		"Switch to "+nextType+" listings", 
		Grid.settings.app.create_handler(this.switchListings, nextType), 
		'Grid'
	) ;
}

/*------------------------------------------------------------------------------------------------------*/
// Display grid
Grid.prototype.display = function()
{
	// set body width
	var body = document.getElementById("quartz-net-com");
    body.style.fontSize = (Grid.settings.FONT_SIZE) + "px" ;
    body.style.fontFamily = "arial,helvetica,clean,sans-serif" ;
    
	var qbody = document.getElementById("quartz-body");
var body_pad = 100 ;
	qbody.style.width = (Grid.settings.TOTAL_PX+body_pad)+"px" ; 
	var qcontent = document.getElementById("quartz-content");
	qcontent.style.width = (Grid.settings.TOTAL_PX+body_pad)+"px" ; 

	var listDiv = document.getElementById("list-body");
	var prev_gridbox = document.getElementById("gridbox");
	
	// Change heading
	this.display_head() ;
	
	// New display
	var gridbox = document.createElement("div");
	gridbox.className = "grid" ;
	gridbox.id = "gridbox" ;
	
	var timebar_day_select = this._timebar_day_select() ;
	gridbox.appendChild(timebar_day_select) ;

	var timebar_hour_select = this._timebar_hour_select() ;
	gridbox.appendChild(timebar_hour_select) ;

	var timebar_hours = this._timebar_hours() ;
	gridbox.appendChild(timebar_hours) ;

	// Display recording schedule
	if (Grid.settings.SHOW_PVR)
	{
		for (var pvr_index=0; pvr_index < this.schedule_list.length; ++pvr_index)
		{
			var schedule = this.schedule_list[pvr_index].display() ;
			gridbox.appendChild(schedule) ;
			
			this.dom['schedule'][pvr_index] = schedule ;
		}
	}

	// Replace previous display with the new one
	listDiv.replaceChild(gridbox, prev_gridbox) ;
	this.dom['gridbox'] = gridbox ;
	
	// Add channels - filter out non-displayable channels
	var chans = this.channels.values(function(chan) {return chan.displayable();} ) ;
// log.dbg(this.logDebug>=2, "Grid.display() - "+chans.length+" chans (limited to "+Grid.settings.DISPLAY_CHANS+")") ;

	// Display
	var first_chan=Grid.settings.DISPLAY_CHANIDX ;
	var last_chan=first_chan + Grid.settings.DISPLAY_CHANS-1 ;
	var	max_chan = chans.length-1 ;
	if (last_chan > max_chan)
	{
		last_chan = max_chan ;
	}
	
	// see if we want to scroll channels
	var scroll_chans = false ;
	if (max_chan >= Grid.settings.DISPLAY_CHANS) scroll_chans = true ;

	for (var idx=first_chan; idx <= last_chan; idx++)
	{
// log.dbg(this.logDebug>=2, " + chan "+idx) ;
		chans[idx].display(gridbox, scroll_chans, idx, first_chan, last_chan, max_chan) ;
	}

/*
	// Check widths are correct
	for (var i=0; i<chans.length; i++)
	{
// log.dbg(this.logDebug, " + chan "+i) ;
		chans[i].check_chan_display() ;
	}
*/



}



//------------------------------------------------------------------------------------------------------
// Create DOM for day select bar
Grid.prototype._timebar_day_select = function()
{
	var timebar_day_select = document.createElement("div");
	timebar_day_select.className = "timesel" ;

	var today = Grid.settings.DISPLAY_DATE_INFO.DAYNAME ;
	var today_day = Grid.settings.DISPLAY_DATE_INFO.DAY ;
	var day_suffix = DateUtils.day2suffix(today_day) ;
	var today_month = DateUtils.monthname(Grid.settings.DISPLAY_DATE_INFO.DT) ;

	// calc date of first displayed day
	var date = Grid.settings.DISPLAY_DATE_INFO.DT ;
	date.setDate(date.getDate() - Grid.settings.DISPLAY_DATE_INFO.DAYNUM);

	var dt_prev = new Date(date.toString()) ;
	dt_prev.setDate(dt_prev.getDate() - 1);
	var dt_next = new Date(date.toString()) ;
	dt_next.setDate(dt_next.getDate() + 7);

/*
	ol
		li "label"
			a
				span <date>
			/a
		/li

		li 
			ol
				li "day"
					a
						span <day>
					/a
				/li
				..
			/ol
		/li
	/ol

*/

	var ol = document.createElement("ol");
	timebar_day_select.appendChild(ol) ;

	// Label
	var li = document.createElement("li");
	ol.appendChild(li) ;
	li.style.width = Grid.settings.DATE_LABEL_PX+'px' ;
	li.className = "label" ;

	var a = document.createElement("a");
	li.appendChild(a) ;
	a.className = "prev" ;

	var span = document.createElement("span");
	a.appendChild(span) ;
	span.appendChild(document.createTextNode(today+' '+today_day+day_suffix+' '+today_month)) ;


	// Days
	var li2 = document.createElement("li");
	ol.appendChild(li2) ;
	li2.style.width = Grid.settings.TOTAL_DAY_PX+'px' ;

	var ol2 = document.createElement("ol");
	li2.appendChild(ol2) ;


	// Prev week
	var liPrev = document.createElement("li");
	ol2.appendChild(liPrev) ;
	liPrev.className = "day nav" ;
	liPrev.style.width = Grid.settings.DAY_NAV_PX+'px' ;
	liPrev.style.marginTop = '4px' ;
	liPrev.style.marginBottom = '4px' ;
	liPrev.style.marginLeft = Grid.settings.DAY_MARGIN_PX+'px' ;
	liPrev.style.marginRight = Grid.settings.DAY_MARGIN_PX+'px' ;
	liPrev.style.padding = '0px' ;

	var a = document.createElement("a");
	liPrev.appendChild(a) ;
	a.style.marginLeft = '0px' ;
	a.style.marginRight = '0px' ;
	a.setAttribute("title", "Last week ; "+dt_prev) ; 
	$(a).click(Grid.settings.app.create_handler(Grid.settings.app.set_date, dt_prev)) ; 
	$(liPrev).click(Grid.settings.app.create_handler(Grid.settings.app.set_date, dt_prev)) ; 
	
	var span = document.createElement("span");
	a.appendChild(span) ;
	span.style.marginLeft = '0px' ;
	span.style.marginRight = '0px' ;
	span.appendChild(document.createTextNode("<")) ;


	// Days
	for (var i=0; i < DateUtils.DAY_NAMES.length; ++i)
	{			
		var day = DateUtils.DAY_NAMES[i] ;
		var cname = "day" ;
		if (day == today)
		{
			cname += " daysel" ;
		}

		var liDay = document.createElement("li");
		ol2.appendChild(liDay) ;
		liDay.className = cname ;
		liDay.style.width = Grid.settings.DAY_PX+'px' ;
		liDay.style.marginTop = '4px' ;
		liDay.style.marginBottom = '4px' ;
		liDay.style.marginLeft = Grid.settings.DAY_MARGIN_PX+'px' ;
		liDay.style.marginRight = Grid.settings.DAY_MARGIN_PX+'px' ;
		liDay.style.padding = '0px' ;

		var a = document.createElement("a");
		liDay.appendChild(a) ;
		a.setAttribute("title", date.toString()) ; 
		
	
		if (day != today)
		{
			var dt = new Date(date.toString()) ;
			$(a).click(Grid.settings.app.create_handler(Grid.settings.app.set_date, dt)) ; 
			$(liDay).click(Grid.settings.app.create_handler(Grid.settings.app.set_date, dt)) ; 
		}
		
		var span = document.createElement("span");
		a.appendChild(span) ;
		span.appendChild(document.createTextNode(day)) ;
		
		date.setDate(date.getDate() + 1);
	}

	// Next week
	var liNext = document.createElement("li");
	ol2.appendChild(liNext) ;
	liNext.className = "day nav" ;
	liNext.style.width = Grid.settings.DAY_NAV_PX+'px' ;
	liNext.style.marginTop = '4px' ;
	liNext.style.marginBottom = '4px' ;
	liNext.style.marginLeft = Grid.settings.DAY_MARGIN_PX+'px' ;
	liNext.style.marginRight = Grid.settings.DAY_MARGIN_PX+'px' ;
	liNext.style.padding = '0px' ;

	var a = document.createElement("a");
	liNext.appendChild(a) ;
	a.style.marginLeft = '0px' ;
	a.style.marginRight = '0px' ;
	a.setAttribute("title", "Next week ; "+dt_next) ; 
	$(a).click(Grid.settings.app.create_handler(Grid.settings.app.set_date, dt_next)) ; 
	$(liNext).click(Grid.settings.app.create_handler(Grid.settings.app.set_date, dt_next)) ; 
	
	var span = document.createElement("span");
	a.appendChild(span) ;
	span.style.marginLeft = '0px' ;
	span.style.marginRight = '0px' ;
	span.appendChild(document.createTextNode(">")) ;


	
	return timebar_day_select ;
}


//------------------------------------------------------------------------------------------------------
// Create DOM for hour select bar
Grid.prototype._timebar_hour_select = function()
{
	var timebar_hour_select = document.createElement("div");
	timebar_hour_select.className = "timesel" ;
	
	var ol = document.createElement("ol");
	timebar_hour_select.appendChild(ol) ;
	ol.style.width = Grid.settings.HOUR_TOTAL_PX+'px' ;
	ol.style.marginLeft = Grid.settings.HOUR_PREV_PX+'px' ;

/*
	ol
		li 
			h4 am
			ul
				li "hour"
					a
						span <hour>
					/a
				/li
				..
			/ul
		/li

		li 
			h4 pm
			ul
				li "hour"
					a
						span <hour>
					/a
				/li
				..
			/ul
		/li
	/ol

*/


	var start_hour = parseInt(Grid.settings.DISPLAY_HOUR, 10) ;
	var end_hour = (start_hour + parseInt(Grid.settings.DISPLAY_PERIOD, 10) -1) % 24 ;

	var ampm_li ;
	var ampm_ul ;
	
	for (var hour=0; hour < Grid.HOURS.length; ++hour)
	{			
		var cname = "hour" ;
		if (end_hour < start_hour)
		{
			// wrap into next day
			if ( (hour >= start_hour) && (hour <= 23) )
			{
				cname += " hoursel" ;
			}
			else if ( (hour <= end_hour) )
			{
				cname += " hoursel" ;
			}
		}
		else
		{
			// Continuous block of hours
			if ( (hour >= start_hour) && (hour <= end_hour) )
			{
				cname += " hoursel" ;
			}
		}
		
		if (hour == 0)
		{
			ampm_li = document.createElement("li");
			ol.appendChild(ampm_li) ;

			h4 = document.createElement("h4");
			h4.appendChild(document.createTextNode("am")) ;
			ampm_li.appendChild(h4) ;			

			ampm_ul = document.createElement("ul");
			ampm_li.appendChild(ampm_ul) ;			
		}
		else if (hour == 12)
		{
			ampm_li = document.createElement("li");
			ol.appendChild(ampm_li) ;

			h4 = document.createElement("h4");
			h4.appendChild(document.createTextNode("pm")) ;
			ampm_li.appendChild(h4) ;			

			ampm_ul = document.createElement("ul");
			ampm_li.appendChild(ampm_ul) ;			
		}

		var li = document.createElement("li");
		ampm_ul.appendChild(li) ;
		li.className = cname ;
		li.style.width = Grid.settings.HOUR_PX+'px' ;
		li.style.marginTop = '4px' ;
		li.style.marginBottom = '4px' ;
		li.style.marginLeft = Grid.settings.HOUR_MARGIN_PX+'px' ;
		li.style.marginRight = Grid.settings.HOUR_MARGIN_PX+'px' ;
		li.style.padding = '0px' ;

		var a = document.createElement("a");
		li.appendChild(a) ;

		if (hour != start_hour)
		{
			$(a).click(Grid.settings.app.create_handler(Grid.settings.app.set_hour, hour)) ; 
			$(li).click(Grid.settings.app.create_handler(Grid.settings.app.set_hour, hour)) ; 
		}
		
		var span = document.createElement("span");
		a.appendChild(span) ;
		span.appendChild(document.createTextNode(Grid.HOURS[hour])) ;
	}

	return timebar_hour_select ;
}

//------------------------------------------------------------------------------------------------------
// Create DOM for hours bar
Grid.prototype._timebar_hours = function()
{
	var timebar_hour = document.createElement("div");
	timebar_hour.className = "time" ;
	
	var HTML = 
		'<ol>'+
			'' ;			

	var hour = Grid.settings.DISPLAY_HOUR ;
	var prev_hour = hour - 1 ;
	if (prev_hour < 0) prev_hour = 23 ;


	HTML += 	
			'<li class="first" style="width: '+Grid.settings.TIME_PX+'px; margin-left: '+Grid.settings.TIME_PREV_PX+'px;">'+
				'<span>'+hour+':00</span>'+
			'</li> ' ;
	
	var mid_hours = Grid.settings.DISPLAY_PERIOD-2 ;
	for (var offset=0; offset < mid_hours; offset++)
	{	
		if (++hour > 23) hour = 0 ;
		HTML += 	
		    	'<li style="width: '+Grid.settings.TIME_PX+'px;">'+
					'<span>'+hour+':00</span>'+
				'</li>' ;
    }		    

	
	if (++hour > 23) hour = 0 ;
	var next_hour = hour+1 ;
	if (next_hour > 23) next_hour = 0 ;

	HTML += 	
  			'<li class="last" style="width: '+Grid.settings.TIME_PX+'px;">'+
				'<span>'+hour+':00</span>'+
			'</li> '+

		'</ol>'+
	'' ;

	timebar_hour.innerHTML = HTML ;
		
	return timebar_hour ;
}


