/*
Title bar for tvguide application

*/

/*------------------------------------------------------------------------------------------------------*/
// Constructor

TitleBar.settings = {} ;


function TitleBar()
{
	this.h2 = null ;
	this.toolDiv = null ;
	
	// point ot global settings
	this.settings = TitleBar.settings ;
}

//Set to true to globally enable debugging
TitleBar.prototype.logDebug = 1 ;



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
TitleBar.setup = function(settings)
{
	if (!TitleBar.settings)
	{
		TitleBar.settings = {} ;
	}
	
	for (var setting in settings)
	{
		TitleBar.settings[setting] = settings[setting] ;
	}
	
}

/*------------------------------------------------------------------------------------------------------*/
// Append a new control to the toolbar
TitleBar.addTool = function(toolImg, toolHint, toolCallback)
{
	var themePath = Settings.themePath() ;
	
	var a = document.createElement("a");
	if (toolHint)
	{
		a.setAttribute("title", toolHint) ;
	}
	this.toolDiv.appendChild(a) ;
	$(a).click(toolCallback) ; 
	
		var img = document.createElement("img");
		img.src = this.settings.app.getImage(toolImg) ;
		a.appendChild(img) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Display grid heading
TitleBar.display_head = function(titleText, titleHint, titleCallback, currTool)
{
	var themePath = Settings.themePath() ;
	var app = TitleBar.settings.app ;
	
	//	<!-- Heading -->
	//	<div class="hd" id="list-hd">
	//
	//		<div id="gridhd">
	//			<h2>
	//				<a href="#">TV listings</a>
	//			</h2>
	//			
	//			<div id="toolbar">
	//				<img src="css/theme/black/tbend.gif" /> 
	//				
	//				<a href="#" onclick="Settings.set();"><img src="css/theme/black/tools.png" /></a>
	//			</div>
	//		</div>
	//
	//	</div>
	
	var headDiv = document.getElementById("list-hd");
	var prev_gridhd = document.getElementById("gridhd");
	
	// New display
	var gridhd = document.createElement("div");
	gridhd.id = "gridhd" ;
	
		// h2
		this.h2 = document.createElement("h2");
		this.h2.id = "titlebar" ;
		gridhd.appendChild(this.h2) ;

			// a
			var a = document.createElement("a");
			if (titleHint)
			{
				a.setAttribute("title", titleHint) ; 
			}
			this.h2.appendChild(a) ;
			if (titleCallback)
			{
				$(a).click(titleCallback) ; 
			}
			a.appendChild(document.createTextNode(titleText)) ;

		// toolbar
		this.toolDiv = document.createElement("div");
		this.toolDiv.id = "toolbar" ;
		gridhd.appendChild(this.toolDiv) ;
		
			var img = document.createElement("img");
			img.src = this.settings.app.getImage("tbend") ;
			this.toolDiv.appendChild(img) ;
			
			// Settings
			this.addTool("tools", "Edit settings", app.create_handler(Settings.set, "")) ;
			
			// Grid
			if (currTool != 'Grid')
			{
				this.addTool("tv", "EPG", app.create_handler(app.showGrid, "")) ;
			}
			else
			{
				this.addTool("tv-grey", "", null) ;
			}
				
			// Recordings list
			if (currTool != 'RecList')
			{
				this.addTool("reclist", "Recordings", app.create_handler(app.showRecordings, "")) ;
			}
			else
			{
				this.addTool("reclist-grey", "", null) ;
			}
			
			// Search
			if (currTool != 'SearchList')
			{
				function new_search_handler()
				{
				   	return function() { 
				   		app.showSearch(SearchList.latestSearch) ;
				   	} ;
				} 
				this.addTool("search", "Search", new_search_handler()) ;
			}
			else
			{
				this.addTool("search-grey", "", null) ;
			}
			
			// Recorded programs
			if (currTool != 'Recorded')
			{
				this.addTool("play", "Recorded Programs", app.create_handler(app.showRecorded, "")) ;
			}
			else
			{
				this.addTool("play-grey", "", null) ;
			}
			
			// Recorded programs
			if (currTool != 'ChanSel')
			{
				this.addTool("chansel", "Displayed Channels", app.create_handler(app.showChanSel, "")) ;
			}
			else
			{
				this.addTool("chansel-grey", "", null) ;
			}
			
			// Recorded programs
			if (currTool != 'Scan')
			{
				this.addTool("scan", "Scan for channels", app.create_handler(app.showScan, "")) ;
			}
			else
			{
				this.addTool("scan-grey", "", null) ;
			}
			
			
			// Finish with help
			$("<a>")
				.attr(
					'href', "php/doc/index.html",
					'title', "HELP!"
						)
				.appendTo( $(this.toolDiv) )
				.append(
					$("<img>")
						.attr("src", this.settings.app.getImage("help"))
				) ;
			
	
	// Replace previous display with the new one
	headDiv.replaceChild(gridhd, prev_gridhd) ;
}

