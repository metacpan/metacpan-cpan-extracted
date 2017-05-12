/*
Scan for new channels
*/

/*======================================================================================================*/
// Constructor
/*======================================================================================================*/

Scan.settings = {} ;
Scan.DEBUG_REFRESH = 0 ;
Scan.REFRESH_PERIOD = 3000 ;
Scan.NUM_FREQ_COLS = 6 ;

function Scan()
{
	// fields
	this.PID = 0 ;
	this.PERCENT = 0 ;
	this.RUNNING = 0 ;
	this.COMPLETE = 0 ;
	this.FREQ = 0 ;
	this.FREQS = [] ;
	this.CHANNELS = [] ;
	
	this.timer = null ;
	this.tickCount = 0 ;
	
	
	// dom
	this.gridbox$ = null ;
	
	// add a ref to the global settings
	this.settings = Scan.settings ;
}

Scan.INT_FIELDS = ['PID', 'PERCENT', 'COMPLETE', 'RUNNING', 'FREQ'] ;

//Map for CHANNELS data
//
// 0 = LCN
// 1 = Name
// 2 = TSID
// 3 = Network
Scan.MAP_CHANS = {
	'LCN'		: 0,	
	'Name'		: 1,	
	'TSID'		: 2,	
	'Network'	: 3,
	'Type'		: 4	
} ;

//Map for FREQS data
//
// 0 = Freq
// 1 = Tuned
// 2 = Current freq
Scan.MAP_FREQS = {
	'Freq'		: 0,	
	'Seen'		: 1,	
	'Tuned'		: 2,	
	'Current'	: 3
} ;


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
Scan.setup = function(settings)
{
	// Copy settings
	for (var setting in settings)
	{
		Scan.settings[setting] = settings[setting] ;
	}
	
	// make our popup bigger
	Scan.settings.POPUP_WIDTH_PX = 600 ;
}



/*------------------------------------------------------------------------------------------------------*/
// Add/Create channels
//
Scan.prototype.update = function(data)
{
	Profile.start('Scan.update') ;

	$.extend(
		this,
		{
			COMPLETE 	: 0,
			PERCENT		: 0,
			RUNNING		: 0,
			CHANNELS	: [],
			FREQS		: []
		},
		data || {}
	) ;
	
	// Ensure integer fields are integers
	for (var i in Scan.INT_FIELDS)
	{
		var field = Scan.INT_FIELDS[i] ;
		if (this.hasOwnProperty(field))
		{
			this[field] = parseInt(this[field], 10) ;
		}
	}

	Profile.stop('Scan.update') ;
}



/*------------------------------------------------------------------------------------------------------*/
//Display heading
Scan.prototype.display_head = function()
{
	TitleBar.display_head("Scan Frequencies", "", null, 'Scan') ;
}


/*------------------------------------------------------------------------------------------------------*/
//Display contents
Scan.prototype.display = function()
{
	// clear any pending timeouts
	this.update_timer() ;
	
	// set body width
	$("#quartz-net-com")
		.css({
			fontSize:	Scan.settings.FONT_SIZE,
			fontFamily:	"arial,helvetica,clean,sans-serif"
		}) ;
	
	var body_pad = 100 ;
	$("#quartz-body")
		.width(Scan.settings.TOTAL_PX+body_pad) ;
	$("#quartz-content")
		.width(Scan.settings.TOTAL_PX+body_pad) ;
	
	// Change heading
	this.display_head() ;
	
	// New display
	var gridbox = document.createElement("div");
	gridbox.className = "grid" ;
	gridbox.id = "gridbox" ;
	
	this.gridbox$ = $("<div>")
		.addClass("grid")
		.attr('id', "gridbox")
			.append(
				$("<div>")
					.attr("id", "scanContents")
			) ;
	

	$("#gridbox")
		.replaceWith(this.gridbox$) ;
	
	if (this.COMPLETE)
	{
		this.tickCount = 0 ;
		this.display_scan() ;
	}
	else
	{
		this.tickCount = (this.tickCount+1) % 9 ;
		this.display_progress() ;
	}
	
}

/*------------------------------------------------------------------------------------------------------*/
//Set up to allow new scan start
Scan.prototype.display_scan = function()
{
	$("#scanContents div").remove() ;

	var freqfile = '/usr/share/dvb/dvb-t/uk-Oxford' ;
	var clean = 1 ;
	var adapter = '100' ;
	
	
	// TODO: Add options to (a) set and send freq file / country (b) do clean scan
	var div$ = $("<div>")
		.addClass("scanButton")
		.append(
			$("<a>Scan</a>")
				.attr("title", "Start Scan")
				.click(function() { 
					this.COMPLETE = 0 ;
					Scan.settings.app.startScan({
//						file	: freqfile,
//						clean	: clean,
//						adapter	: adapter
					})
				})
		)
		.appendTo("#scanContents") ;
	
	this.display_freqs() ;
	this.display_chans() ;
	
}

/*------------------------------------------------------------------------------------------------------*/
//Set up to allow new scan start
Scan.prototype.display_progress = function()
{
	// clear existing
	$("#scanContents div").remove() ;

if (Scan.DEBUG_REFRESH)
{
	var div$ = $("<div>")
		.css({
			color: 'blue',
		})
		.append(
			$("<a>Refresh...</a>")
				.attr("title", "Update display")
				.click(function() { 
					Scan.settings.app.showScan()
				})
		)
		.appendTo("#scanContents") ;
}	
	
	// progress
	this.display_percent() ;
	
	// frequencies
	this.display_freqs() ;
	
	// Channels
	this.display_chans() ;
	
if (!Scan.DEBUG_REFRESH)
{
	// re-display every 10secs if not finished
	if (!this.COMPLETE)
	{
		var timerCallback = function(scanObj) {
			
			return function(){
				
				// are we currently on display?
				if (Scan.settings.app.currentPage == "scan")
				{
					// show scan
					Scan.settings.app.showScan() ;
				}
				else
				{
					// not being displayed so kill timer
					scanObj.updateTimer() ;
				}
			} ;
		}
		this.update_timer( timerCallback(this), Scan.REFRESH_PERIOD) ;
	}
}


}

/*------------------------------------------------------------------------------------------------------*/
//Set up to allow new scan start
Scan.prototype.display_chans = function()
{
	if (this.CHANNELS.length == 0)
		return ;
	
	
	var html = "" ;
	for (var i in this.CHANNELS)
	{
		var network = "" ;
		if (this.CHANNELS[i][ Scan.MAP_CHANS.Network ])
		{
			network = this.CHANNELS[i][ Scan.MAP_CHANS.Network ] ;
		}
		html += '' 
			+ '	<div class="scanRow">'
			+ '		<ol>'
			+ '			<li class="lcol">'
			+ '				<div class="scanLCN">'
			+ '					' + this.CHANNELS[i][ Scan.MAP_CHANS.LCN ]
			+ '				</div>'
			+ '			</li>'
			+ '			<li class="lcol">'
			+ '				<div class="scanType">'
			+ '					' + this.CHANNELS[i][ Scan.MAP_CHANS.Type ]
			+ '				</div>'
			+ '			</li>'
			+ '			<li class="lcol">'
			+ '				<div class="scanChan">'
			+ '					' + this.CHANNELS[i][ Scan.MAP_CHANS.Name ] 
			+ '				</div>'
			+ '			</li>'
			+ '			<li class="lcol">'
			+ '				<div class="scanNet">'
			+ '					' + network 
			+ '				</div>'
			+ '			</li>'
			+ '		</ol>'
			+ '	</div>'
			;
	}
	
	var div$ = $("<div>")
		.html('<div id="chans" class="scanInfo">'
			+ '	<div class="scanHead">'
			+ '		Channels'
			+ '	</div>'
			+ '	<div class="scanRow" id="scanChanHead">'
			+ '		<ol>'
			+ '			<li class="lcol">'
			+ '				<div class="scanLCN">'
			+ '					LCN'
			+ '				</div>'
			+ '			</li>'
			+ '			<li class="lcol">'
			+ '				<div class="scanType">'
			+ '					Type'
			+ '				</div>'
			+ '			</li>'
			+ '			<li class="lcol">'
			+ '				<div class="scanChan">'
			+ '					Channel'
			+ '				</div>'
			+ '			</li>'
			+ '			<li class="lcol">'
			+ '				<div class="scanNet">'
			+ '					Network'
			+ '				</div>'
			+ '			</li>'
			+ '		</ol>'
			+ '	</div>'
			+ html
			+ '</div>'
		)
		.appendTo("#scanContents") ;
}


/*------------------------------------------------------------------------------------------------------*/
Scan.prototype.display_percent = function()
{
	var width = parseInt(Scan.settings.TOTAL_PX * 0.70, 10) ;
	var tick = '' ;
	for (i=0; i<this.tickCount; ++i)
	{
		tick += '.' ;
	}
	var div$ = $("<div>")
		.html('<div id="progress" class="scanInfo">'
			+ '	<div class="scanRow">'
			+ '		<ol>'
			+ '			<li class="lcol">'
			+ '				Progress: '
			+ '			</li>'
			+ '			<li class="lcol">'
			+ '				<div class="progressWrap" style="width: '+width+'px;"> <div class="progressInner" style="width: ' + this.PERCENT + '%;"> </div>  </div>' 
			+ '			</li>'
			+ '			<li class="lcol">'
			+ '				' + this.PERCENT + '%' + '  ' + tick
			+ '			</li>'
			+ '		</ol>'
			+ '	</div>'
			+ '</div>'
		)
		.appendTo("#scanContents") ;
}

/*------------------------------------------------------------------------------------------------------*/
Scan.prototype.display_freqs = function()
{
	// Handle start where we don't get the full list
	if ( (this.FREQS.length == 0) && (this.FREQ > 0) )
	{
		var entry = [] ;
		entry[ Scan.MAP_FREQS.Freq ] = this.FREQ ;
		entry[ Scan.MAP_FREQS.Current ] = "1" ;
		entry[ Scan.MAP_FREQS.Tuned ] = "0" ;
		entry[ Scan.MAP_FREQS.Seen ] = "0" ;
		this.FREQS = [ entry ] ;
	}
	
	// Show freqs
	var html = "" ;
	if (this.FREQS.length == 0)
	{
		html = "Setting up frequency list, please wait..." ;
	}
	else
	{
		for (var i in this.FREQS)
		{
			var cname = "" ;
			if (this.FREQS[i][ Scan.MAP_FREQS.Current ] == "1")
			{
				cname = " scanFreqCurr" ;
			}
			else if (this.FREQS[i][ Scan.MAP_FREQS.Tuned ] == "1")
			{
				cname = " scanFreqDone" ;
			}
			else if (this.FREQS[i][ Scan.MAP_FREQS.Seen ] == "1")
			{
				cname = " scanFreqFail" ;
			}
			
			if (i % (Scan.NUM_FREQ_COLS+1) == Scan.NUM_FREQ_COLS)
			{
				html += '' 
					+ '		</ol>'
					+ '	</div>'
					+ '	<div class="scanRow">'
					+ '		<ol>'
					;
			}
			html += '' 
				+ '			<li class="lcol">'
				+ '				<div class="scanFreq' + cname + '">'
				+ '					' + this.FREQS[i][ Scan.MAP_FREQS.Freq ] + ' Hz'
				+ '				</div>'
				+ '			</li>'
			;
		}
		
	}
	
	// Only display if we have some freqs OR we've started scan
	if ( (this.FREQS.length > 0) || (!this.COMPLETE) )
	{
		var div$ = $("<div>")
		.html('<div id="freqs" class="scanInfo">'
			+ '	<div class="scanHead">'
			+ '		Frequencies'
			+ '	</div>'
			+ '	<div class="scanRow">'
			+ '		<ol>'
			+ html
			+ '		</ol>'
			+ '	</div>'
			+ '</div>'
		)
		.appendTo("#scanContents") ;
	}
}

/*------------------------------------------------------------------------------------------------------*/
Scan.prototype.update_timer = function(cb, timeout)
{
	if (this.timer)
	{
		window.clearTimeout(this.timer) ;
		this.timer = null ;
	}
	
	if (timeout && cb)
	{
		this.timer = window.setTimeout(cb, timeout);
	}
}

