/*
A multiplex recording container - contains multiple multirecrams being recorded at the same time

"Inherits" Prog
*/

// Map from array index to multirec field
Multirec.MULTIREC_MAP = {
	0	: "multid", 
	1	: "start_time", 
	2	: "start_date", 
	3	: "end_time", 
	4	: "end_date", 
	5	: "duration_mins", 
	6	: "pvr"
} ;

//filled in during init
Multirec.MULTIREC_FIELDS = {} ;

//Set to true to globally enable debugging
Multirec.prototype.logDebug = false ;


/*======================================================================================================*/
// Constructor
/*======================================================================================================*/
//
// Create from an array of values (see MULTIREC_MAP)
//
/*	
	this.pid = pid ;
	this.chan = chan ;
	this.start_time = start_time ;
	this.start_date = start_date ;
	this.end_time = end_time ;
	this.end_date = end_date ;
	this.title = title ;
	this.genre = genre ;
	this.description = description ;
	this.duration_mins = duration_mins ;
	this.record = record || 0 ;
	this.film = false ;
*/
function Multirec(args)
{
	// log.dbg(this.logDebug, " + Multirec()", args) ;
	
	// Base off Prog
	var multirec_args = [] ;
	for (var i in Multirec.MULTIREC_MAP)
	{
		var field = Multirec.MULTIREC_MAP[i] ;
		multirec_args[field] = null ;
		if (args[i])
		{
			multirec_args[field] = args[i] ;
		}
	}

	// need to create a "pid" for the schedule SortedObjList
	multirec_args["pid"] = "A-B-" + multirec_args["multid"] ;
	
	var prog_args = [] ;
	for (var i in Prog.PROG_MAP)
	{
		var field = Prog.PROG_MAP[i] ;
		prog_args[i] = multirec_args[field] ;
	}

	// log.dbg(this.logDebug, " + + create Prog base:", prog_args) ;
	
	Prog.call(this, prog_args) ;
	
	this.type = 'Multirec' ;

	// multiplex id
	this.multid = multirec_args["multid"] ;
	
	// Container for the programs
	this.progs = [] ;
}

// Subclass from Prog
Multirec.prototype = new Prog() ;

// Remove Prog properties from prototype
for (m in Multirec.prototype)
{
	if (typeof m == 'function')
		continue ;
	
	delete Multirec.prototype[m] ;
}

// Set constructor
Multirec.prototype.constructor = Multirec ;

/*======================================================================================================*/
// OVER-RIDE
/*======================================================================================================*/

/*------------------------------------------------------------------------------------------------------*/
// Create the multirecram content in a new 'a' element & return the 'a' element when we're done
Multirec.prototype._create_content = function()
{
	// nasty magic number (difference between li width and the span widths
	var width = (this._display_mins * Multirec.settings.PX_PER_MIN)-9 ;

//debug
if (width <= 0)
{
	width=1;
}

	var a = document.createElement("a");
	var class_name = "url uid" ;	// NOTE: Do *NOT* use variable name 'class' - IE fails!

	return a ;
}

/*------------------------------------------------------------------------------------------------------*/
Multirec.prototype.popup_contents = function(popupDiv, record_select)
{
	// log.dbg(this.logDebug, " + + Multirec.popup_contents()") ;

	var span = document.createElement("span");
	span.className = "wrap" ;
	popupDiv.appendChild(span) ;
	
	span.innerHTML = 
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
			'</span>' ;

	var desc = document.createElement("div");
	desc.className = "description" ;
	popupDiv.appendChild(desc) ;
	
		var spanDesc = document.createElement("span");
		spanDesc.className = "summary" ;
		spanDesc.appendChild(document.createTextNode('Multiplex Record ['+this.multid+']'));
		desc.appendChild(spanDesc) ;

	var ul = document.createElement("ul");
	popupDiv.appendChild(ul) ;
	
	for (var i = 0; i < this.progs.length; i++)
	{
		var prog = this.progs[i] ;
		var progid = "prog"+i ;

		var li = document.createElement("li");
		ul.appendChild(li) ;
		
		var progdiv = document.createElement("div");
		progdiv.id = progid ;
		progdiv.className = "multi" ;
		li.appendChild(progdiv);
		
		// log.dbg(this.logDebug, " + + Multirec.popup_contents() - progdiv "+i+" = "+progdiv) ;

		if (progdiv)
			prog.popup_contents(progdiv, record_select) ; 
	}
	
	
}

/*------------------------------------------------------------------------------------------------------*/
//return the class name fotr recording 
Multirec.prototype.record_class = function()
{
	return "multirec" ;
}



///////////////////////////////////////////////////////////////////////////////////

/*------------------------------------------------------------------------------------------------------*/
Multirec.prototype.add_prog = function(rid, chanid, record, prog, multid)
{
	// save in this multiplexs record's list of progs
	this.progs.push(prog) ;
	
	// Create a recording entry for the prog
	var recording = new Recording(rid, chanid, record, prog, multid) ;
	return recording ;
}

// work out reverse map
for (var i in Multirec.MULTIREC_MAP)
{
	var field = Multirec.MULTIREC_MAP[i] ;
	Multirec.MULTIREC_FIELDS[field] = i ;
}
	
