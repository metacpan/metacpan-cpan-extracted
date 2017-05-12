/*
Show the list of channels
*/

/*======================================================================================================*/
// Constructor
/*======================================================================================================*/

ChanSel.settings = {} ;

function ChanSel()
{
	// fields
	this.list = [] ;
	
	// add a ref to the global settings
	this.settings = ChanSel.settings ;
}



// Map from array index to entry field
ChanSel.MAP = {
		0	: "chanid", 
		1	: "name", 
		2	: "show", 
		3	: "iplay",
		4	: "type",
		5	: "display",
} ;

ChanSel.INT_FIELDS = ['chanid', 'show', 'iplay', 'display'] ;

function ChanSelEntry(args)
{
	// fields
	for (var i in ChanSel.MAP)
	{
		var field = ChanSel.MAP[i] ;
		this[field] = null ;
		if (args[i])
		{
			this[field] = args[i] ;
		}
	}
	
	// Ensure integer fields are integers
	for (var i in ChanSel.INT_FIELDS)
	{
		var field = ChanSel.INT_FIELDS[i] ;
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
ChanSel.setup = function(settings)
{
	// Copy settings
	for (var setting in settings)
	{
		ChanSel.settings[setting] = settings[setting] ;
	}
	
	// make our popup bigger
	ChanSel.settings.POPUP_WIDTH_PX = 600 ;
}



/*------------------------------------------------------------------------------------------------------*/
// Add/Create channels
//
ChanSel.prototype.update = function(chansel_data)
{
	Profile.start('ChanSel.update') ;

	// Remove existing
	this.list = [] ;
	
	// Create list of objects
	for (var i=0; i < chansel_data.length; ++i)	{

		// create a new chansel entry based on the data received
		var chansel = new ChanSelEntry(chansel_data[i]) ;
		
		// Add it to the list
		this.list.push(chansel) ;
	}

	Profile.stop('ChanSel.update') ;
}



/*------------------------------------------------------------------------------------------------------*/
//Display heading
ChanSel.prototype.display_head = function()
{
	TitleBar.display_head("Channel Display Selection", "", null, 'ChanSel') ;

	// Add some extra tools
	TitleBar.addTool("sync", "Update channels", ChanSel.settings.app.updateChanSel) ;
}


/*------------------------------------------------------------------------------------------------------*/
//Display contents
ChanSel.prototype.display = function()
{
	// set body width
	$("#quartz-net-com")
		.css({
			fontSize:	ChanSel.settings.FONT_SIZE,
			fontFamily:	"arial,helvetica,clean,sans-serif"
		}) ;
	
	var body_pad = 100 ;
	$("#quartz-body")
		.width(ChanSel.settings.TOTAL_PX+body_pad) ;
	$("#quartz-content")
		.width(ChanSel.settings.TOTAL_PX+body_pad) ;
	
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
					.attr("id", "chanContents")
			) ;
	

	$("#gridbox")
		.replaceWith(gridbox$) ;
	
	
	this.showChanSel("TV Channels", "tv", gridbox$) ;
	this.showChanSel("Radio Channels", "radio", gridbox$) ;
	
}


/*------------------------------------------------------------------------------------------------------*/
ChanSel.prototype.showChanSel = function(heading, idName, gridbox$)
{
	
	// Each "cell" is 220px
	var CELL_WIDTH = 220 ;
	var TOTAL_WIDTH = ChanSel.settings.TOTAL_PX ;
	
	var len = this.list.length ;
	
	//	<div id="tv" class="channels">
	//		
	//		<div class="chanHead">
	//			TV Channels
	//		</div>
	//	
	//		<div class="chanRow">
	//			<ol>
	//				<li class="lcol">
	//					<div class="channel">
	//						<span class="chan">BBC1</span>
	//						<span class="lcn">1</span>
	//						<span class="sel">
	//						<a title="Click to display or not display channel in EPG">
	//						<img src="check-1.png" >
	//						</a>
	//						</span>
	//					</div>
	//				</li>
	
	var div$ = $("<div>")
		.addClass("channels")
		.attr("id", idName)
		.append(
			$("<div>")
			.addClass("chanHead")
			.text(heading)
		)
		.appendTo("#chanContents", gridbox$) ;
	
	var chanRowDiv$ = null ;
	var col = 0 ;
	var re = new RegExp(idName) ;
	for (var idx=0; (idx < len); ++idx )
	{
		var chansel = this.list[idx] ;
		
		// First check type (match hd-tv & tv with type 'tv')
		if (chansel.type.search(re) < 0)
		{
			continue ;
		}
		
		// Update column position
		if (col == 0)
		{
			chanRowDiv$ = $("<div>")
				.addClass("chanRow")
				.append(
					$("<ol>")
				)
				.appendTo('#'+idName, div$) ;
		}
		col += CELL_WIDTH ;
		
		
		//				<li class="lcol">
		//					<div class="channel">
		//						<span class="chan">BBC1</span>
		//						<span class="lcn">1</span>
		//						<span class="sel">
		//						<a title="Click to display or not display channel in EPG">
		//						<img src="check-1.png" >
		//						</a>
		//						</span>
		//					</div>
		//				</li>
		
		var li$ = $("<li>")
				.html(
					'<div class="channel">'
				+	'	<span class="chan">'+chansel.name+'</span>'
				+	'	<span class="lcn">'+chansel.chanid+'</span>'
				+	'	<span class="sel">'
				+	'		<a title="Click to display or not display channel in EPG">'
				+	'			<img src="" >'
				+	'		</a>'
				+	'	</span>'
				+	'	</a>'
				+	'</div>'
				+	''
				) ;

		var image = "check-" + chansel.show ;
		
		var img$ = $("img", li$)
			.attr("src", this.settings.app.getImage(image)) ;

		function factoryChanSel(chanSelEntry, thisImg$) {
			return function(event) {
				
				// toggle image
				var show = (chanSelEntry.show + 1) % 2 ;
				var image = "check-" + show ;
				thisImg$.attr("src", ChanSel.settings.app.getImage(image)) ;
				
				// do Ajax
				ChanSel.settings.app.setChanSel({
					chanid: chanSelEntry.chanid,
					show:	show
				});
			} ;
		}
		$("a", li$)
			.click(factoryChanSel(chansel, img$)) ;

		$("ol", chanRowDiv$)
			.append(li$) ;
		
		if ( (col + CELL_WIDTH) >= TOTAL_WIDTH)
		{
			// start new row
			col = 0 ;
		}
	}
}


