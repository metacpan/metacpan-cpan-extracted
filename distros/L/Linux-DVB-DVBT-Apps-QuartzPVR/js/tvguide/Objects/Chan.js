/*
Manages the programs for a single channel

Version 2.00

*/

/*------------------------------------------------------------------------------------------------------*/
// Constructor

Chan.settings = {} ;

function Chan(chanid, name, iplay, show, type)
{
	this.chanid = chanid ;
	this.name = name ;
	this.iplay = parseInt(iplay, 10) ;
	this.show = parseInt(show, 10) ;
	this.type = type ;

// log.dbg(this.logDebug, "Chan("+name+")") ;

	// Keep a list of programs
	this.progs = new SortedObjList( "pid", Prog.prog_sort ) ;
	this.dummy_pid = 1 ;
	
// log.dbg(this.logDebug, "Chan("+name+") - END") ;
	
	// Point to global settings
	this.settings = Chan.settings ;

}

// Set to true to globally enable debugging
Chan.prototype.logDebug = false ;

//TODO: specify display range - use range to "slice" list of progs

/*------------------------------------------------------------------------------------------------------*/
//Set the display windows
//start date & hour, display period in hours
Chan.setup = function(settings)
{
	if (!Chan.settings)
	{
		Chan.settings = {} ;
	}
	
	for (var setting in settings)
	{
		Chan.settings[setting] = settings[setting] ;
	}

	// send to programs
	Prog.setup(Chan.settings) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Function that sorts by numeric channel id
Chan.chanidSort = function(a, b)
{
	var a_id = parseInt(a.chanid, 10) ;
	var b_id = parseInt(b.chanid, 10) ;
	return a_id - b_id ;
}


/*------------------------------------------------------------------------------------------------------*/
// Returns true if chan is to be shown
//
Chan.prototype.displayable = function()
{
	return this.show ;
}

/*------------------------------------------------------------------------------------------------------*/
// Add/Create progs
//
// progs is an ARRAY of the form:
//
// [
//      [
//          <prog settings (see Prog.PROG_MAP)>
//      ],
//      ... 
// ]
//
Chan.prototype.update_progs = function(progs)
{
	Profile.start('Chan.update_progs') ;

// log.dbg(this.logDebug, "Chan.update_progs()") ;

	// Create/update prog objects
	var prev_end_mins = 0 ;
	var prev_end_time, prev_end_date ;
	for (var i=0; i<progs.length; ++i)
	{
		var pid = progs[i][Prog.PROG_FIELDS["pid"]] ;
		var prog = this.progs.get(pid) ;

		// for debug
		var title = progs[i][Prog.PROG_FIELDS["title"]] ;

		// get this prog's start time
		var start_mins ;
		var start_time ;
		var start_date ;
		if (prog)
		{
			start_mins = prog.start_mins ;
			start_date = prog.start_date ;
			start_time = prog.start_time ;
		}
		else
		{
			// Pre-calculate this program's start time
			start_time = progs[i][Prog.PROG_FIELDS["start_time"]] ;
			start_date = progs[i][Prog.PROG_FIELDS["start_date"]] ;
			start_mins = DateUtils.datetime2mins(start_date, start_time) ;
		}
		
		
		// Make sure there is no gap
		if (prev_end_mins)
		{
			if (start_mins > prev_end_mins)
			{
				var prog_args = [] ;
				prog_args[Prog.PROG_FIELDS["pid"]] = this.dummy_pid++ ;
				prog_args[Prog.PROG_FIELDS["chanid"]] = this.dummy_pid++ ;
				prog_args[Prog.PROG_FIELDS["start_time"]] = prev_end_time ;
				prog_args[Prog.PROG_FIELDS["start_date"]] = prev_end_date ;
				prog_args[Prog.PROG_FIELDS["end_time"]] = start_time ;
				prog_args[Prog.PROG_FIELDS["end_date"]] = start_date ;
				prog_args[Prog.PROG_FIELDS["duration_mins"]] = start_mins - prev_end_mins ;
				prog_args[Prog.PROG_FIELDS["title"]] = '(missing)' ;
				prog_args[Prog.PROG_FIELDS["genre"]] = '*missing*' ;
				prog_args[Prog.PROG_FIELDS["description"]] = 'Program information is missing' ;
				prog_args[Prog.PROG_FIELDS["record"]] = 0 ;
				prog_args[Prog.PROG_FIELDS["pvr"]] = 0 ;
				prog_args[Prog.PROG_FIELDS["tva_series"]] = '' ;
				
				// Add a "dummy" prog to fill the gap
				this.progs.add(new Prog(prog_args)) ;
			}
		}
		
		// see if prog already created
		if (!prog)
		{
// log.dbg(this.logDebug, " + create ("+title+") @ "+start+" pid="+pid) ;
			// Create it
			prog = new Prog(progs[i]) ;
			this.progs.add(prog) ;
		}
		else
		{
// log.dbg(this.logDebug, " + update ("+title+") @ "+start+" pid="+pid) ;
			// otherwise update it
			prog.update(progs[i]) ;
		}
		
		// keep track of where this Prog finishes
		prev_end_mins = prog.end_mins ;
		prev_end_date = prog.end_date ;
		prev_end_time = prog.end_time ;
	}

//	// update program recordings list "schedule"
//	this.recordings.update(this.progs) ;

	Profile.stop('Chan.update_progs') ;
}



/*------------------------------------------------------------------------------------------------------*/
// Add a channel to the DOM - append to specified node
Chan.prototype.display = function(node, scroll_chan, chan_idx, first_chan, last_chan, max_chan)
{
Profile.start("Chan.display") ;

	// structure is:
	//
	// h2
	// div channel vcalender schedule

//// log.dbg(this.logDebug, "Chan.display("+this.name+") - start") ;

	// programs
	var div = document.createElement("div") ;
	div.className = "channel" ; 
	node.appendChild(div);

	// See if channel scrolling is required
	//
	// Need to account for the case where we've scrolled down to show only the last channel. In this case we DO want to be able to 
	// page back again (otherwise we're stick!)
	//
	var first = false ;
	var last = false ;
	// don't scroll if first or last
	if ((chan_idx == 0) || (chan_idx == max_chan)) 
	{
		// Normally don't want to scroll in this case, but allow for showing the last channel
		if (first_chan != max_chan)
		{
			scroll_chan = false ;
		}
	}
	if (scroll_chan)
	{
		// Scrolling - now see if we need to add 'up' or 'down' arrows
		if (chan_idx == first_chan) first = true ;
		if (chan_idx == last_chan) last = true ;
	}

//// log.dbg(this.logDebug, " + idx="+chan_idx+", first_chan="+first_chan+", last_chan="+last_chan+", max="+max_chan+", scroll="+scroll_chan+" (first="+first+", last="+last+")") ;

	// Add the programs
	var ol = document.createElement("ol") ;

	var li = document.createElement("li");
	li.style.width = Chan.settings.CHAN_PX+"px" ; // need to set width to ensure css 'overflow: hidden' works correctly
	li.className = "vevent" ; 
	
	var heading = document.createElement("h2");
	heading.style.width = Chan.settings.CHAN_PX+"px" ; 
	var label_node = heading ;

	var span = document.createElement("span");
	span.style.width = (Chan.settings.CHAN_PX-8)+"px" ; // need to set width to ensure css 'overflow: hidden' works correctly 
	span.appendChild(document.createTextNode(this.name)) ;
	
	// depends on scrolling
	var a = document.createElement("a");
	if (scroll_chan)
	{
		heading.appendChild(a) ;
		a.className="channel-name" ;
		label_node = a ;

		var new_start = chan_idx ;
		if (first)
		{
			// page back
			new_start = chan_idx - Chan.settings.DISPLAY_CHANS ;
		}
		else if (last)
		{
			// page forward
			new_start = chan_idx + 1 ;
		}
		else
		{
			// put this channel at top
			new_start = chan_idx ;
		}
		
		// range check
		if (new_start < 0) new_start = 0 ;
		if (new_start > max_chan) new_start = max_chan ;
		$(a).click(GridApp.create_handler(GridApp.set_chanidx, new_start)) ; 
	}
	else
	{
		span.className = "channel-name" ;
	}	

	label_node.appendChild(span) ;
	
	if (first || last)
	{
		var img = document.createElement("img");
		label_node.appendChild(img) ;
		img.style.position = "absolute" ;
		img.style.left = "10px" ;
		
		if (first)
		{
			img.style.top = "3px" ;
//			img.src = "./images/up.png" ;
			img.src = this.settings.app.getImage("up") ;
		}
		else
		{
			img.style.bottom = "3px" ;
//			img.src = "./images/down.png" ;
			img.src = this.settings.app.getImage("down") ;
		}
	}


	//li.innerHTML = '<a href="#NEWPROG" class="channel-name"><span >'+this.name+"</span></a>" ;
	
	li.appendChild(heading);
	ol.appendChild(li);


	// get list of displayed programs
	var progs = this.progs.values(Prog.prog_in_display) ;
	
	// display each prog
	for (var i=0; i<progs.length; ++i)
	{
		progs[i].display(ol) ;
	}

	div.appendChild(ol) ;

Profile.stop("Chan.display") ;

	return div ;
}

/*------------------------------------------------------------------------------------------------------*/
// Scan the programs and ensure they are displayed correctly
Chan.prototype.check_chan_display = function()
{
	// get list of displayed programs
	var progs = this.progs.values(Prog.prog_in_display) ;

	// check this prog, adjusting previous prog in not correct
	var prev_pid ;
	var start_x ;
	for (var pid in progs)
	{
		if (prev_pid)
		{
			Prog.check_prog_display(progs[prev_pid], progs[pid], start_x) ;
		}
		else
		{
			// first prog
			start_x = $(progs[pid].dom_node).pos().left ;
		}
		
		prev_pid = pid ;
	}

}


/*------------------------------------------------------------------------------------------------------*/
// Try to retrieve the program indicated by it's program id
Chan.prototype.get_prog = function(pid)
{
	return this.progs.get(pid) ;
}

/*------------------------------------------------------------------------------------------------------*/
// DEBUG: show program list
Chan.prototype._print_progs = function(proglist, msg)
{
	if (!msg) msg="" ;
	log.dbg(this.logDebug, "DEBUG: Prog list "+msg) ;
	
	// display each prog
	for (var i in proglist)
	{
		log.dbg(this.logDebug, " + prog ("+proglist[i].title+") @ "+proglist[i].start_time+" pid="+proglist[i].pid) ;
	}
	
	log.dbg(this.logDebug, "DEBUG: Prog list - END") ;
}

