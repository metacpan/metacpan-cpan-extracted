/*
A program recording object

*/

/*------------------------------------------------------------------------------------------------------*/
// Constructor for a Recording entry
function Recording(rid, chanid, record, prog, multid)
{
	this.rid = rid ;			// recording index number (MySQL index)
	this.chanid = chanid ;		// channel id
	this.record = record ;		// record level
	this.prog = prog ;			// ref to Prog object
	this.pid = prog.pid ;		// used for indexing
	this.multid = multid || 0 ;	// multiplex container id (0 = no multiplex)
}

/*------------------------------------------------------------------------------------------------------*/
// Sort 2 programs
Recording.prog_sort = function(a, b) 
{
	return Prog.prog_sort(a.prog, b.prog) ;
}

/*------------------------------------------------------------------------------------------------------*/
// Will program be displayed
Recording.prog_in_display = function(a) 
{
	return Prog.prog_in_display(a.prog) ;
}

