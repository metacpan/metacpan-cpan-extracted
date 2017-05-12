/*
Maintains the list of programs scheduled for recording

Displays this as a "thin bar" at the top of the display with highlighted regions indicating program recordings

*/


/*------------------------------------------------------------------------------------------------------*/
// Constructor
function Schedule(pvr, settings)
{
	this.pvr = pvr ;			// pvr adapter number <adapter>:<frontend>
	this.settings = settings ;	// ref to Grid.settings
	this.recordings = new SortedObjList( "pid", Recording.prog_sort ) ;
}

//Set to true to globally enable debugging
Schedule.prototype.logDebug = false ;


/*------------------------------------------------------------------------------------------------------*/
// Clear the list
//
Schedule.prototype.empty = function()
{
	// blow away old list
	this.recordings.empty() ;
}



/*------------------------------------------------------------------------------------------------------*/
// Add a new recording to the list
//
Schedule.prototype.add = function(rid, chanid, record, prog, multid)
{
	// create entry and add it
	var recording = new Recording(rid, chanid, record, prog, multid) ;
	this.recordings.add(recording) ;
	return recording ;
}


/*------------------------------------------------------------------------------------------------------*/
// Get the recording list
Schedule.prototype.values = function()
{
	// get list
	var values = this.recordings.values() ;
	
	return values ;
}


/*------------------------------------------------------------------------------------------------------*/
// Create schedule DOM
Schedule.prototype.display = function()
{
Profile.start("Schedule.display()") ;
// log.dbg(this.logDebug, "Schedule.display() pvr "+this.pvr) ;

	var schedule = document.createElement("div");
//	schedule.className = "channel vcalendar sched" ;
	schedule.className = "sched" ;

/*	
	var schedule_content =
		'<ol>'+
		 		'<li style="width: '+Grid.settings.CHAN_PX+'px;" class="vevent">'+
					'<h2 class="sched" style="width: '+Grid.settings.CHAN_PX+'px;"></h2>'+
				'</li>'+
		 		'<li style="width: '+Grid.settings.TOTAL_TIME_PX+'px;" class="vevent">'+
					'<a href="" class="url uid">'+
					'</a>'+
				'</li>'+
		'</ol>'+
	'' ;

	schedule.innerHTML = schedule_content ; 
*/

	var ol = document.createElement("ol");
	schedule.appendChild(ol) ;
	
	var li = document.createElement("li");
	ol.appendChild(li) ;
	li.style.width = this.settings.CHAN_PX+'px' ;
	li.className = "vevent" ;
	
	var h2 = document.createElement("h2");
	li.appendChild(h2) ;
	h2.style.width = this.settings.CHAN_PX+'px' ;
	h2.className = "sched" ;
	h2.appendChild(document.createTextNode("pvr"+this.pvr)) ;

	
//var list1 = this.recordings.values() ;
//// log.dbg(this.logDebug, "Display schedule - all", list1) ;
	
// TODO: calc real schedule...
/*
	li = document.createElement("li");
	ol.appendChild(li) ;
	li.style.width = this.settings.TOTAL_TIME_PX+'px' ;
	li.className = "vevent" ;
*/

	// list of recordings to be displayed
	var list = this.recordings.values(Recording.prog_in_display) ;

	/*
		re
		hours		S		   S+1		   S+2		  S+3		  S+n 		    E
					|			|			|			|			|			|
		prog
				:////////:      :                       :    :          :             :
				ps       pe
				
		hours		S		   S+1		   S+2		  S+3		  S+n 		    E
					|			|			|			|			|			|
		prog
				             :////////:      :                       :    :          :             :
				             ps       pe
	
	
		ALGORITHM:
		
		Assumes that the $prog_start_mins and $prog_end_mins have been set to be monotonically increasing
		(i.e. switch to next day gives minutes always > minutes of previous day)
		
		The displayed window is bounded by $start_mins (S) and $end_mins (E). Also, a running pointer $start
		is used which is initialised to $start_mins (S) and then moved to the end of each added program. If the next
		program added starts AFTER $start then blank padding is added.
		
		
		$start_mins																	$end_mins
		|																					|
		|//prog1////:	pad		://new prog/////:											|
		|			^			^															|
		|			:			:															|
		|		$start		new $prog_start													|
	
		Obviously, only those programs that have their end time AFTER $start_mins or their start time
		BEFORE $end_mins are added (with their start/end truncated as appropriate)
				
				$start_mins														$end_mins
					|																|
					|																|
					|																|
				:///A////:        :////B///:                                  ://////C/////:
	
				:   :/A//:        :////B///:                                  ://C//:
	            :---:																:------:
	          truncated																truncated
	          
	
	
	*/

// log.dbg(this.logDebug, "Display schedule - filtered", list) ;

var total_mins=0;
var total=0;
	
	var start = this.settings.DISPLAY_START_MINS ;
// log.dbg(this.logDebug, " + START "+this.settings.DISPLAY_START_MINS+" END "+this.settings.DISPLAY_END_MINS) ;
	for (var i = 0; i < list.length; i++)
	{
// log.dbg(this.logDebug, " + start="+start) ;
// log.dbg(this.logDebug, " + prog @ "+list[i].prog.start_time+" duration="+list[i].prog.duration_mins) ;

		// Check for preceding padding
		if (list[i].prog.start_mins > start)
		{
			// Create padding
			var pad_width = (list[i].prog.start_mins - start) * this.settings.PX_PER_MIN ;

			li = document.createElement("li");
			ol.appendChild(li) ;
			li.style.width = pad_width+'px' ;
			li.className = "vevent" ;

			var a = document.createElement("a");
			li.appendChild(a) ;
		}

		// show program
		list[i]._display_mins = list[i].prog.calc_display_mins() ;
		width = list[i]._display_mins * this.settings.PX_PER_MIN ;
		
		li = document.createElement("li");
		ol.appendChild(li) ;
		li.style.width = width+'px' ;
		li.className = "vevent" ;

		var a = document.createElement("a");
		li.appendChild(a) ;
		a.className = "url uid " ; 
		a.className = a.className + list[i].prog.record_class() ;
		
		// add a popup display to show program details
		list[i].prog.add_prog_popup(a) ;

	
		// Update start
		start = list[i].prog.end_mins ;
	}

// log.dbg(this.logDebug, " + start="+start+"  END="+this.settings.DISPLAY_END_MINS) ;
	
	// check for blank at end of list
	if (start < this.settings.DISPLAY_END_MINS)
	{
		// Create padding
		var pad_mins = (this.settings.DISPLAY_END_MINS - start) ;
		var pad_width = (this.settings.DISPLAY_END_MINS - start) * this.settings.PX_PER_MIN ;

		li = document.createElement("li");
		ol.appendChild(li) ;
		li.style.width = pad_width+'px' ;
		li.className = "vevent" ;

		var a = document.createElement("a");
		li.appendChild(a) ;
		a.className = "pad" ;
	}

// log.dbg(this.logDebug, "FINAL total mins="+total_mins+" px="+total+" Expected mins="+Grid.settings.TOTAL_TIME_WIDTH) ;

Profile.stop("Schedule.display") ;

	return schedule ;
}



