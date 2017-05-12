/*
Show the latest recorded programs
*/

/*======================================================================================================*/
// Constructor
/*======================================================================================================*/

Recorded.settings = {} ;

//Create the popup object we'll use
Recorded.popup = new Popup();


function Recorded()
{
	// fields
	this.list = [] ;
	
	// add a ref to the global settings
	this.settings = Recorded.settings ;
	this.popup = Recorded.popup ;
}



// Map from array index to entry field
Recorded.MAP = {
	0	: "pid", 
	1	: "rid", 
	2	: "rectype", 
	3	: "title", 
	4	: "text", 
	5	: "date", 
	6	: "start", 
	7	: "duration", 
	8	: "chanid", 
	9	: "adapter", 
	10	: "type",
	11	: "record",
	12	: "priority",
	13	: "file",
	14	: "filePresent",
	15	: "changed",
	16	: "status"
} ;

Recorded.INT_FIELDS = ['chanid', 'adapter', 'record', 'priority', 'filePresent'] ;

function RecordedEntry(args)
{
	// fields
	for (var i in Recorded.MAP)
	{
		var field = Recorded.MAP[i] ;
		this[field] = null ;
		if (args[i])
		{
			this[field] = args[i] ;
		}
	}
	
	// Do some date/time calculation
	var datestr = this.date.replace(/\-/g, '/') ;
	this.start_dt = new Date( datestr + ' ' + this.start ) ;
	this.changed_dt = new Date( this.changed.replace(/\-/g, '/') ) ;
	
	var end_ms = this.start_dt.getTime() + (DateUtils.time2mins(this.duration) * 60 * 1000) ;
	this.end_dt = new Date(end_ms) ;
	this.end = DateUtils.dt2hm(this.end_dt) ;
	
	this.updateStr = DateUtils.dt2hm(this.changed_dt) + " on " + DateUtils.dt2string(this.changed_dt) ;
	this.dateStr = DateUtils.dt2string(this.start_dt) ;
	
	// Ensure integer fields are integers
	for (var i in Recorded.INT_FIELDS)
	{
		var field = Recorded.INT_FIELDS[i] ;
		this[field] = parseInt(this[field], 10) ;
	}
	
}



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
Recorded.setup = function(settings)
{
	// Copy settings
	for (var setting in settings)
	{
		Recorded.settings[setting] = settings[setting] ;
	}
	
	// make our popup bigger
	Recorded.settings.POPUP_WIDTH_PX = 600 ;
}



/*------------------------------------------------------------------------------------------------------*/
// Add/Create progs
//
// Array of recordings "HASHes"
//
Recorded.prototype.update = function(recorded_data)
{
	Profile.start('Recorded.update') ;

	// Remove existing
	this.list = [] ;
	
	// Create list of objects
	for (var i=0; i < recorded_data.length; ++i)	{

		// create a new recorded entry based on the data received
		var recorded = new RecordedEntry(recorded_data[i]) ;
		
		// Add it to the list
		this.list.push(recorded) ;
	}

	Profile.stop('Recorded.update') ;
}



/*------------------------------------------------------------------------------------------------------*/
//Display heading
Recorded.prototype.display_head = function()
{
	TitleBar.display_head("Recorded Programs", "", null, 'Recorded') ;
}


/*------------------------------------------------------------------------------------------------------*/
//Display contents
Recorded.prototype.display = function()
{
	// set body width
	$("#quartz-net-com")
		.css({
			fontSize:	Recorded.settings.FONT_SIZE,
			fontFamily:	"arial,helvetica,clean,sans-serif"
		}) ;
	
	var body_pad = 100 ;
	$("#quartz-body")
		.width(Recorded.settings.TOTAL_PX+body_pad) ;
	$("#quartz-content")
		.width(Recorded.settings.TOTAL_PX+body_pad) ;
	
	// Change heading
	this.display_head() ;
	
	// New display
	var gridbox = document.createElement("div");
	gridbox.className = "grid" ;
	gridbox.id = "gridbox" ;
	
	var gridbox$ = $("<div>")
		.addClass("grid")
		.attr('id', "gridbox")
			.append(
				$("<div>")
					.attr("id", "recordedContents")
			) ;
	

	$("#gridbox")
		.replaceWith(gridbox$) ;
	
//	// Add content
////???????????????????????????????????
//
//	

//	<div id="recordedContents">
//	
//		<div id="recent" class="recProgs">
//		
//			<div class="recHead">
//				Recent Programs
//			</div>
//		
//			<div class="recRow">
//				<ol>
//					<li>
//						<div class="recProg">
//							<a title="prog">
//							<img src="../css/theme/black/images/video-iplay.png" >
//							</a>
//						</div>
//						<div class="recCaption">
//							Big bang Theory.ts
//						</div>
//					</li>
//					...
//				</ol>
//			</div>
//			
//			...
//	
	
	var lastWeek = new Date() ;
	lastWeek.setDate( lastWeek.getDate() - 7 ) ;
	var lastMonth = new Date() ;
	lastMonth.setDate( lastMonth.getDate() - 31 ) ;
	
	var idx = 0 ;
	idx = this.showRecorded("Last 7 days", "recent", idx, gridbox$, lastWeek) ;
	idx = this.showRecorded("Last 4 weeks", "month", idx, gridbox$, lastMonth) ;
	idx = this.showRecorded("Older Programs", "older", idx, gridbox$) ;
	
}


/*------------------------------------------------------------------------------------------------------*/
Recorded.prototype.showRecorded = function(heading, idName, idx, gridbox$, afterDate)
{
	
	// Each "cell" is 128px
	var CELL_WIDTH = 128 ;
	var TOTAL_WIDTH = Recorded.settings.TOTAL_PX ;
//var numCols = parseInt(TOTAL_WIDTH / CELL_WIDTH, 10) ;
	
	var len = this.list.length ;
	
	if (idx >= len)
	{
		return idx ;
	}
	
	var div$ = $("<div>")
		.addClass("recProgs")
		.attr("id", idName)
		.append(
			$("<div>")
			.addClass("recHead")
			.text(heading)
		)
		.appendTo("#recordedContents", gridbox$) ;
	
	var recRowDiv$ = null ;
	var col = 0 ;
	for (var done=false; (idx < len) && !done; ++idx )
	{
		var recorded = this.list[idx] ;
		
		// First check date
		if (afterDate)
		{
//			var datestr = recorded.changed.replace(/\-/g, '/') ;
//			var date = new Date( datestr ) ;
			
			if (recorded.changed_dt < afterDate)
			{
				done = true ;
				continue ;
			}
		}
		
		
		// Update column position
		if (col == 0)
		{
			recRowDiv$ = $("<div>")
				.addClass("recRow")
				.append(
					$("<ol>")
				)
				.appendTo('#'+idName, div$) ;
		}
		col += CELL_WIDTH ;
		
		
		//	<li class="lcol">
		//		<div class="recProg">
		//			<a title="prog">
		//			<img src="../css/theme/black/images/video-iplay.png" >
		//			</a>
		//		</div>
		//		<div class="recCaption">
		//			Big bang Theory.ts
		//		</div>
		//	</li>
		
		var li$ = $("<li>")
				.html(
					'<div class="recProg">' +
						'<a title="prog">' +
						'<img src="">' +
						'</a>' +
					'</div>' +
					'<div class="recCaption '+(recorded.filePresent ? '' : 'fileNotPresent')+'">' +
						recorded.title +
					'</div>'
				) ;

		var image = "video" ;
		if (recorded.type == "radio")
		{
			image = "audio" ;
		}
		if (recorded.rectype == "iplay")
		{
			image += "-iplay" ;
		}
		
		$("img", li$)
			.attr("src", this.settings.app.getImage(image)) ;
	
		// add a popup to show info
		this.add_recorded_popup($("a", li$).get(0), recorded) ;
	
		$("ol", recRowDiv$)
			.append(li$) ;
		
		if ( (col + CELL_WIDTH) >= TOTAL_WIDTH)
		{
			// start new row
			col = 0 ;
		}
	}
	
//	$("#gridbox")
//		.replaceWith(gridbox$) ;
//	
	
	return idx ;
	
}

/*------------------------------------------------------------------------------------------------------*/
//Add a popup window to show recorded program information. 
//
//<!-- 
//
//2	: "rectype", 
//3	: "title", 
//4	: "text", 
//5	: "date", 
//6	: "start", 
//7	: "duration", 
//8	: "chanid", 
//9	: "adapter", 
//10	: "type",
//11	: "record",
//12	: "priority",
//13	: "file",
//14	: "filePresent",
//15	: "changed",
//16	: "status"
//
//
//Tue 21st Aug 2011
//21:00 - 22:00
//"All Watched Over by Machines of Loving Grace"
//The Monkey in the Machine and the
//Machine in the Monkey: Why do humans find the machine vision so
//beguiling - does it excuse our failure? Contains disturbing scenes.
//
//[Last update: 01:15 on Tue 21st Aug 2011]
//
//[rec] [priority]
//
//File: /served/videos/PVR/Misc/TEST/CSI-Miami/Series RAUF/20110809205800-A young girl is kidnapped and the CSIs only witness is a blind man who hears the abduction, leading Horatio to an old nemesis serving a life sentence in prison.ts
//
//
//
//-->
//
//
//	<div
//		style="position: absolute; 
//		visibility: visible; left: 220px; top: 366px; z-index: 100; width: 600px;"
//		class="popupContent">
//	
//		<div>
//			<span class="wrap">
//				<span class="times">
//				Tue 21st Aug 2011
//				</span>
//			</span>
//			<span class="wrap">
//				<span class="times">
//					<span class="dtstart"><abbr title="2011-06-06T21:00" class="value"></abbr>21:00</span> - 
//					<span class="dtend"><abbr title="2011-06-06T22:00" class="value"></abbr>22:00</span>
//				</span>
//			</span>
//			<div class="description">
//				<span class="summary">All Watched Over by Machines of Loving Grace</span>
//				The Monkey in the Machine and the
//				Machine in the Monkey: Why do humans find the machine vision so
//				beguiling - does it excuse our failure? Contains disturbing scenes.
//			</div>
//			<div class="update">
//				<span class="dupdate"><abbr title="2011-06-06T21:00" class="value"></abbr>[Last update: 01:15 on Tue 21st Aug 2011]</span>
//			</div>
//			<div class="info">
//				<img src="../css/theme/black/images/record-multi.png"><img src="../css/theme/black/images/priority-high.png">
//			</div>
//			<div class="fileName">
//				File: /served/videos/PVR/Misc/TEST/QI XL/Series KVEGDJ/20110808233800-Happiness.ts
//			</div>
//		</div>
//	</div>
//
Recorded.prototype.add_recorded_popup = function(node, recobj)
{
	var thisObj = this ;
	
	// use this width
	var popup_width = thisObj.settings.POPUP_WIDTH_PX ;
	
	var recSettings = {
		//-----------------------------------------------------
		create_popup: function(settings, x, y, popup_callback) {
			
			var popupDiv = $("<div>")
				.html(
					'<span class="wrap">'
				+	'	<span class="times">'
				+	recobj.dateStr
				+	'	</span>'
				+	'</span>'
				+	'<span class="wrap">'
				+	'	<span class="times">'
				+	'		<span class="dtstart">'+recobj.start+'</span> - ' 
				+	'		<span class="dtend">'+recobj.end+'</span>'
				+	'	</span>'
				+	'</span>'
				+	'<div class="description">'
				+	'	<span class="summary">'+recobj.title+'</span>'
				+	recobj.text
				+	'</div>'
				+	'<div class="update">'
				+	'	<span class="dupdate">[Last update: '+recobj.updateStr+']</span>'
				+	'</div>'
				+	'<div class="info">'
				+	'	<img src="'+Prog.RecImg(recobj.record)+'"><img src="'+Prog.PriorityImg(recobj.priority)+'">'
				+	'</div>'
				+	'<div class="fileName '+(recobj.filePresent ? '' : 'fileNotPresent')+'">'
				+	'	File: ' + recobj.file
				+	'</div>'
				)
				.get(0);

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
		}
	} ;
	
	PopupHandler.add_popup(node, recSettings) ;
}


