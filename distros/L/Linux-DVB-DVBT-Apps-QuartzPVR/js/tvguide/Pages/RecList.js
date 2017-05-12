/*
Manages a list of TV program recording requests

*/

/*======================================================================================================*/
// Constructor
/*======================================================================================================*/

RecList.settings = {} ;

//Create the popup object we'll use
RecList.popup = new Popup();


function RecList(override)
{
	var args = {
		
		index 		: "pid" ,
		subindex 	: "progsList" ,
		sort 		: RecList.sort,
		rowClass 	: "",
		subrowClass : "lprog",
			
		popupClassName 	: "recListPop",
		recselCallback 	: RecList.setRecordings,
		priCallback 	: RecList.setRecordings
			
	} ;
	
	// override with settings - provided for derived objects
	if (override && (typeof override == "object"))
	{
		for (var setting in override)
		{
			args[setting] = override[setting] ;
		}
	}
	
	TvList.call(this, args) ;
	
	// add a ref to the global settings
	this.settings = RecList.settings ;
}


// Subclass from TvList
RecList.prototype = new TvList() ;

// Remove TvList properties from prototype
for (m in RecList.prototype)
{
	if (typeof m == 'function')
		continue ;
	
//	if (m == 'settings')
//		continue ;
	
	delete RecList.prototype[m] ;
}

// Set constructor
RecList.prototype.constructor = RecList ;


//Sort programs such that the newest active recordings appear first
RecList.sort = function(a,b) {
	
	var res = 0 ;

	/*
	low
	
		X  ( X < Y)
		
		a  (a < b)
		
		b
		
		----------------------------
		
		Y  (Y > X)
		
		m
		
		n
	
	
	high
	*/
	
	// start by preferring Recordings with scheduled progs
	var cmp = (b.progsList.length>0?1:0) - (a.progsList.length>0?1:0) ; 
	if (cmp==0)
	{
		// both either have scheduled progs or none - sort by start
		if (a.sortMins && b.sortMins)
		{
			res = a.sortMins - b.sortMins ;
		}
		else
		{
			res = a.prog.title>b.prog.title ? 1 : (a.prog.title==b.prog.title?0 : -1) ;
//log.debug("-RecList.sort(a.title="+a.prog.title+", b.title="+b.prog.title+") res="+res+", type="+(typeof res) ) ;	
//log.debug("-a=", a) ;	
//log.debug("-b=", b) ;	
		}
	}
	else
	{
		res = parseInt(cmp, 10) ;
	}
//log.debug("RecList.sort(alen="+a.progsList.length+", amins="+a.sortMins+", blen="+b.progsList.length+", bmins="+b.sortMins+") res="+res+", type="+(typeof res) ) ;	
	return res;
} 

//Sort programs such that the newest active recordings appear first
RecList.subsort = function(a,b) {
	var cmp = Prog.prog_sort(a, b) ;
//log.debug("RecList.subsort() res="+cmp+", type="+(typeof cmp) ) ;	
	return cmp;
} 


// Map from array index to entry field
RecList.MAP = {
	0	: "rid", 
	1	: "pid", 
	2	: "chanid", 		
	3	: "start_time", 
	4	: "start_date", 
	5	: "end_time", 
	6	: "end_date", 
	7	: "duration_mins", 
	8	: "title", 
	9	: "record",
	10	: "priority",
	11	: "pathspec",
	
	12	: "progs_array"
} ;

// Add the following extra fields to a Prog
RecList.EXTENDED_PROG = [
	"rid",
	"record",
	"priority",
	"pathspec"
] ;


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
RecList.setup = function(settings)
{
	// Update base class
	TvList.setup(settings) ;

	// Copy settings
	for (var setting in TvList.settings)
	{
		RecList.settings[setting] = TvList.settings[setting] ;
	}
	
	// Add updates
	RecList.settings.DATE_PX = 150 ;
	RecList.settings.TIME_PX = 150 ;
	RecList.settings.CHAN_PX = 150 ;
	
	// NOTE: reclist instances all point to this RecList.settings object
	RecList.settings.ENTRY_TITLE_PX = RecList.settings.TOTAL_PX - (
		RecList.settings.HIDE_PX +
		RecList.settings.PRI_PX +
		RecList.settings.DIR_PX +
		RecList.settings.CHAN_PX +
		RecList.settings.REC_PX 
	) ;

	RecList.settings.PROG_TITLE_PX = 300 ;
	RecList.settings.PROG_TEXT_PX = RecList.settings.TOTAL_PX - (
			RecList.settings.HIDE_PX +
			RecList.settings.PROG_TITLE_PX +
			RecList.settings.DATE_PX +
			RecList.settings.TIME_PX +
			RecList.settings.CHAN_PX +
			RecList.settings.PRI_PX +
			RecList.settings.DIR_PX +
			RecList.settings.REC_PX 
		) ;

}

/*------------------------------------------------------------------------------------------------------*/
// Change record level
//RecList.setRecordings = function(record, pid, rid, priority)
RecList.setRecordings = function(prog)
{
	RecList.settings.app.setRecordings(prog) ;
}


/*======================================================================================================*/
// SPECIFIC
/*======================================================================================================*/


/*------------------------------------------------------------------------------------------------------*/
// Add extra fields to the standard Prog
//
RecList.prototype.extendProg = function(prog, args)
{
	for (var i=0; i < RecList.EXTENDED_PROG.length; i++)
	{
		var field = RecList.EXTENDED_PROG[i] ;
		if (field in args)
		{
			prog[field] = args[field] ;
		}
		else
		{
			prog[field] = "" ;
		}
	}
	return prog ;
}

/*------------------------------------------------------------------------------------------------------*/
// Add/Create progs
//
// Array of recordings "HASHes"
//
RecList.prototype.update = function(reclist_data)
{
	Profile.start('RecList.update') ;

	// Remove existing
	this.list.empty() ;
	
	// Create list of objects
	for (var i=0; i < reclist_data.length; ++i)	{
		// create a new recording entry based on the data received
		var recording = this.createEntry(reclist_data[i]) ;
		
		// Add it to the list
		this.list.add(recording) ;
	}

	Profile.stop('RecList.update') ;
}


//========================================================================================================
// OVERRIDE
//========================================================================================================

/*------------------------------------------------------------------------------------------------------*/
//Create a thing Object based on data array
//
RecList.prototype.createEntry = function(args)
{
	// Create a mapping from name -> value
	var entry_args = [] ;
	for (var i in RecList.MAP)
	{
		var field = RecList.MAP[i] ;
		entry_args[field] = null ;
		if (args[i])
		{
			entry_args[field] = args[i] ;
		}
	}
	entry_args["genre"] = "" ;
	
	// Create prog args
	var prog_args = [] ;
	for (var i in Prog.PROG_MAP)
	{
		var field = Prog.PROG_MAP[i] ;
		if (entry_args.hasOwnProperty(field))
		{
			prog_args[i] = entry_args[field] ;
		}
		else
		{
			prog_args[i] = -1 ;
		}
	}
	var prog = new Prog(prog_args) ;
	// Extend prog
	this.extendProg(prog, entry_args) ;
	
	// Create Recording : rid, chanid, record, prog, multid
	var recording = new Recording(entry_args["rid"], entry_args["chanid"], entry_args["record"], prog, 0) ;
	
	// Amend recording to add missing attributes
	recording.channel = RecList.settings.app.allChans[entry_args["chanid"]].name ;
	
	// Process progs list
	recording.progsList = new SortedObjList("pid", RecList.subsort) ;
	for (var i = 0; i < entry_args["progs_array"].length; i++)
	{
		var prog = new Prog(entry_args["progs_array"][i]) ;
		
		// Extend prog
		this.extendProg(prog, entry_args) ;

		// Add to list
		recording.progsList.add(prog) ;
	}

	// Set the date to use for sorting - if there are progs, use the first prog in the list
	// i.e. the next prog to be recorded.
	recording.sortMins = recording.start_mins ;
	if (recording.progsList.length)
	{
		var progs = recording.progsList.values() ;
		recording.sortMins = progs[0].start_mins ;
	}
	
	
	return recording ;
}


/*------------------------------------------------------------------------------------------------------*/
//Is this entry active
RecList.prototype.entry_inactive = function(entry)
{
	var inactive  = 0 ;
	if (entry.progsList.length == 0)
	{
		inactive = 1 ;
	}
	return inactive ;
}


/*------------------------------------------------------------------------------------------------------*/
//Display grid heading
RecList.prototype.display_head = function()
{
	TitleBar.display_head("Program Recording List", "", null, 'RecList') ;
	
	// Add some extra tools
	TitleBar.addTool(TvList.IMAGE_MAP["show"], "Show all entries", TvList.global_show_handler(this, "show")) ;
	TitleBar.addTool(TvList.IMAGE_MAP["hide"], "Hide all entries", TvList.global_show_handler(this, "hide")) ;

}


/*------------------------------------------------------------------------------------------------------*/
//Display a list entry
RecList.prototype.display_entry = function(idx, entry, ol)
{
	this.display_recsel(ol, entry.prog) ;

	this.display_chan(ol, entry.channel) ;
	this.display_text(ol, this.settings.ENTRY_TITLE_PX, entry.prog.title) ;

	this.display_prisel(ol, entry.prog) ;
	this.display_dirsel(ol, entry.prog) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Display a sub list under the main entry row
RecList.prototype.display_subentry = function(idx, prog, ol)
{
	var li = this.display_recsel(ol, prog) ;
	this.subentry_firstcol(li) ;
	
	this.display_chan(ol, RecList.settings.app.allChans[prog.chanid].name) ;
	this.display_date(ol, prog.start_date) ;
	this.display_startend(ol, prog.start_time, prog.end_time) ;
	this.display_text(ol, this.settings.PROG_TITLE_PX, prog.title) ;
	this.display_text(ol, this.settings.PROG_TEXT_PX, prog.description) ;
}

