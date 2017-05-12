/*
 * Profile.js: Unobtrusive profiling facility (based on David Flanagan's Log.js)
 *
 * This module defines a single global symbol: a function named profile().
 * Profile a function by calling start() and end() with the function name.
 * 
 * Enabling Profiling
 *
 *   Profile messages are *not* displayed by default.  You can enable the
 *   display of messages in a given category in one of two ways.  The
 *   first is to create a <div> or other container element with an id
 *   of "profile".  For example, place the following in the containing document:
 * 
 *      <div id="profile"></div>
 *
 *   In this case, all profile messages are appended
 *   to this container, which can be styled however you like.
 * 
 *   The second way to enable profile messages is to
 *   set an appropriate profileging option.  To enable, you'd set profile.options.debugEnabled = true.  When you
 *   do this, a <div class="profile"> is created for the profileging messages.
 *   If you want to disable the display of profile messages, even if a container
 *   with a suitable id exists, set another option:
 *   profile.options.debugDisabled=true.  Set this option back to false to 
 *   reenable profile messages of that category.
 *
 * Styling Profile Messages
 * 
 *   In addition to styling the profile container, you can use CSS to
 *   style the display of individual profile messages.  Each profile message
 *   is placed in a <div> tag, and given a CSS class of "profile_message".
 *
 *   If the sorted results are printed, then each entry has the CSS class of "profile_sorted".
 * 
 * Profile Options
 * 
 *   Profiling behavior can be altered by setting properties of the profile.options
 *   object, such as the options described earlier to enable or disable profiling
 *   for given categories.  A few other options are available:
 *
 *     profile.options.scroll: If set, automatically scrolls to show the latest debug entry
 *
 */
 
// Make sure we haven't already been loaded
var Profile;
if (Profile && (typeof Profile != "object" || Profile.NAME))
    throw new Error("Namespace 'Profile' already exists");

// Create our namespace, and specify some meta-information
Profile = {};
Profile.NAME = "Profile";   // The name of this namespace
Profile.VERSION = 1.0;      // The version of this namespace
Profile.div = null;			// Container div
Profile.count = 0 ;

Profile.debug = false ;

// Create an empty options object
Profile.options = {};

// Create an empty object to keep track of start/end times
Profile.times = {} ;

// Array of results - sorted list
Profile.results = [] ;

// Array of results - timeline
Profile.timeline = [] ;




// Start/stop timer for this name. 
Profile._profile = function (start_stop, name) 
{
    // If profiling is explicitly disabled, do nothing
    if (Profile.options["Disabled"]) return;

    // Find the container
    var c = Profile.div ;

	var now = new Date() ;
//	var value = "" ;
	if (start_stop == "start")
	{
		Profile.times[name] = {
			name	: name,
			start	: now,
			stop	: null,
			duration: null,
			count	: Profile.count
		} ;
//		value = "START" ;
	}
	else
	{
//		value = "END = ?" ;
		if (Profile.times[name] && Profile.times[name].start)
		{
			Profile.times[name].stop = now ;
			Profile.times[name].duration = Profile.times[name].stop.valueOf() - Profile.times[name].start.valueOf() ;
			Profile.times[name].count = Profile.count
//			value = "END = "+Profile.times[name].duration+"ms" ;
		}

	}

	if (Profile.times[name])
	{
		// keep all results - used for sorted output
		Profile.results.push(Profile.times[name]) ;

		// Keep track of overheads
		Profile.count++ ;
		
		// Save current object for timeline
		var copy = {} ;
		for (var field in Profile.times[name])
		{
			copy[field] = Profile.times[name][field] ;
		}
		Profile.timeline.push(copy) ;
	}
}



// Start timer for this name.
Profile._start = function(name) { Profile._profile("start", name); };
Profile._stop  = function(name) { Profile._profile("stop", name); };
Profile._null_start = function(name) { };
Profile._null_stop  = function(name) { };



// Start/stop timer for this name. Optionally append a user message
Profile.enable = function (start_stop, name, message) 
{
    // If profiling is explicitly disabled, do nothing
    if (Profile.options["Disabled"]) return;

    // Find the container
    var id = "profile";
    var c = document.getElementById(id);

    // If there is no container, but profiling is enabled,
    // create the container.
    if (!c && Profile.options["Enabled"]) {
        c = document.createElement("div");
        c.id = id;
        c.className = "profile";
        document.body.appendChild(c);
    }

    // If still no container, we ignore the message
    if (!c) return;

	Profile.div = c ;

	Profile.options["Disabled"] = false ;

	Profile.start = Profile._start ;
	Profile.stop = Profile._stop ;

}


// Remove profiling
Profile.disable = function () 
{
	Profile.div = null ;
	Profile.options["Disabled"] = true ;

	Profile.start = Profile._null_start ;
	Profile.stop = Profile._null_stop ;
}


//--------------------------------------------------------
// DISPLAY

// Show timline
Profile._show_timeline = function()
{
	for (var i=0; i<Profile.timeline.length; i++)
	{
	    // Create a <div> element to hold the profile entry
	    var div = document.createElement("div");
	    div.className = "profile_message" ;
	    Profile.div.appendChild(div);
	
	    var table = document.createElement("table");
	    table.border = 1;
		
	    var row = document.createElement("tr");
	    row.vAlign = "top";
	    
	    var rowTime = document.createElement("td");
	    rowTime.className = "profTime" ;
	    var rowName = document.createElement("td");
	    rowName.className = "profName" ;
	    var rowValue = document.createElement("td");
	    rowValue.className = "profValue" ;

		var entry = Profile.timeline[i] ;
		
		var now ;
		var value ;
		if (!entry.stop)
		{
			// no stop - just a start entry
			now = entry.start ;
			value = "START" ;
		}
		else
		{
			// stop entry
			now = entry.start ;
			value = "END = "+entry.duration+"ms" ;
		}
	
		timestamp = "[" + now.getHours() + ":" + now.getMinutes() + ":" + now.getSeconds() + "." + now.getMilliseconds() + "]" ;
	    rowTime.appendChild(document.createTextNode(timestamp));
	    rowName.appendChild(document.createTextNode(entry.name));
	    rowValue.appendChild(document.createTextNode(value));
	
	    // Add the cells to the row, and add the row to the table
	    row.appendChild(rowTime);
	    row.appendChild(rowName);
	    row.appendChild(rowValue);
	
	    table.appendChild(row);
	    div.appendChild(table);
	}

}

// Show sorted results
Profile._show_sorted = function()
{
	// collate based on name
	var collated = {} ;
	for (var i=0; i<Profile.results.length; i++)
	{
		var name = Profile.results[i].name ;
		if (!collated[name])
		{
			collated[name] = {
				name	: name,
				count	: 0,
				total	: 0
			} ;
		} 
		collated[name].count++ ;
		collated[name].total += Profile.results[i].duration ;
	}
	
	// sort based on total time
	var sorted = [] ;
	for (var name in collated)
	{
		sorted.push(collated[name]) ;
	}
	sorted = sorted.sort(function (a, b) 
		{ 
			return a.total - b.total ; 
		}) ;
	 
	// now display
	for (var i=0; i<sorted.length; i++)
	{
	    // Create a <div> element to hold the profile entry
	    var div = document.createElement("div");
	    div.className = "profile_sorted" ;
	    Profile.div.appendChild(div);
	
	    var table = document.createElement("table");
	    table.border = 1;
		
	    var row = document.createElement("tr");
	    row.vAlign = "top";
	    
	    var rowName = document.createElement("td");
	    rowName.className = "profName" ;
	    var rowTime = document.createElement("td");
	    rowTime.className = "profTime" ;
	    var rowCount = document.createElement("td");
	    rowCount.className = "profCount" ;

		var entry = sorted[i] ;
		
	    rowName.appendChild(document.createTextNode(entry.name));
	    rowTime.appendChild(document.createTextNode(entry.total+"ms"));
	    rowCount.appendChild(document.createTextNode(entry.count));
	
	    // Add the cells to the row, and add the row to the table
	    row.appendChild(rowName);
	    row.appendChild(rowTime);
	    row.appendChild(rowCount);
	
	    table.appendChild(row);
	    div.appendChild(table);
	}
	
	collated = {} ;
	sorted = [] ;
}


// Show results so far
Profile.show_results = function () 
{
    // If profiling is explicitly disabled, do nothing
    if (Profile.options["Disabled"]) return;

	Profile._show_timeline() ;
	Profile._show_sorted() ;

}

// Clear out stored results
Profile.clear_results = function () 
{
	Profile.results = [] ;
	Profile.timeline = [] ;
	Profile.times = {} ;
}



// Aliases
Profile.begin = Profile.start;
Profile.end  = Profile.stop;
