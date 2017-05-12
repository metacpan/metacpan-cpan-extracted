/* Settings

Requires: Env.js

 */

var Settings = {

	//=============================================================================
	// DATA
	cookie 	: new Cookie("tvguide"),
	app		: null,
	
	// defaults
	defaults : {
				period		: 4,
				showPvr		: 1,
				progPopup 	: 0,
				theme		: "black",
				profile		: 0,
				debug		: 0
			},
	labels : {
				period		: 'Display Period (hours):',
				showPvr		: 'Display PVR bars:',
				progPopup	: 'Popup prog info:',
				theme		: 'Theme:',
				profile		: 'Profile:',
				debug		: 'Debug:'
			},
	dialog : [
				'period',
				'showPvr',
				'progPopup',
				'theme',
				'debug'
	],

	//=============================================================================
	// METHODS
	
	//-----------------------------------------------------------------------------
	init	: function() {
		
		for (var set in Settings.defaults)
		{
			var val ;
			if (!this.cookie.hasOwnProperty(set)) 
			{
				val = Settings.defaults[set] ;
			}
			else
			{
				val = this.cookie[set] ;
			}
			if (typeof Settings.defaults[set] == "number")
			{
				val = parseInt(val, 10) ;
			}
			this.cookie[set] = val ; 
		}

		// update doc
		this.apply() ;
	},


	//-----------------------------------------------------------------------------
	set : function() {
	
		var content = [] ;
		for (var i=0, len=Settings.dialog.length; i < len; i++)
		{
			var set = Settings.dialog[i] ;
			var contentEntry = {
				type: 'text',
				label: Settings.labels[set],
				name: set,
				value: Settings.cookie[set]
			} ;
			content.push(contentEntry) ;
		}

		var dialog = new Dialog({
		
			title: 'Settings', 
			width: 400,
			content: content,
			buttons: [
				{
					label: 'Accept',
					type: 'ok',
					callback: function(vars) {
						
						for (var i=0, len=Settings.dialog.length; i < len; i++)
						{
							var set = Settings.dialog[i] ;
							var val = vars[set].value ;
							if (typeof Settings.defaults[set] == "number")
							{
								val = parseInt(val, 10) ;
							}
							Settings.cookie[set] = val ;
						}

						// Store the cookie data, which includes the updated visit count.  We set
						// the cookie lifetime to 10 days.  Since we don't specify a path, this
						// cookie will be accessible to all web pages in the same directory as this
						// one or "below" it.  We should be sure, therefore that the cookie
						// name, "visitordata" is unique among these pages.
						Settings.cookie.store(10);
						
						dialog.hide() ;
						
						// update doc
						Settings.apply() ;
					}
				},
				{
					label: 'Cancel',
					type: 'cancel'
				}
			]
			
		}
		) ;
		
		dialog.showCentral() ;
	},
	
	
	
	//-----------------------------------------------------------------------------
	apply : function() 	{

		//** Set theme **
		
		// remove any existing
		$('.themecss').remove() ;
		
		// Create new
		$('<link>')
			.addClass('themecss')
			.attr({
				type: 	'text/css',
				rel:	'stylesheet',
				href:	Env.DIR.CSS_THEME+"/"+Settings.cookie.theme+"/main.css",
				media:	'screen'})
			.appendTo('head') ;
		
	
		//** Set/clear debug **
		Settings._setup_div('debug', 'debug_log', log) ;
//		log.options.scroll = true ;

		//** Set/clear profile **
		Settings._setup_div('profile', 'profile', Profile) ;
		if (Settings.cookie['profile'] > 0)
		{
			// enable
			Profile.enable() ;
		}
		else
		{
			// disable
			Profile.disable() ;
		}

		if (Settings.app)
		{
			Settings.app.redraw() ;
		}
		
	},
	
	//-----------------------------------------------------------------------------
	//** Set/clear named feature with it's related DIV container **
	_setup_div : function(name, id, feature) 	{

		var div = document.getElementById(id);

		if (Settings.cookie[name] > 0)
		{
			// enable
			if (!div) 
			{
				div = document.createElement('div');
				div.id = id ;
				var quartz = document.getElementById("quartz-body");
				quartz.appendChild(div) ;
			} 
			feature.options[name+'Disabled']=false;
			feature.options[name+'Enabled']=true;
		}
		else
		{
			// disable
			if (div) div.parentNode.removeChild(div) ; 

			feature.options[name+'Disabled']=true;
			feature.options[name+'Enabled']=false;
		}
	},
	
	
	//-----------------------------------------------------------------------------
	//** Get debug setting **
	debug : function() 	{
		return Settings.cookie.debug ;
	},

	//-----------------------------------------------------------------------------
	// set the application object
	setApp : function(app) 	{
		Settings.app = app ;
	},

	//-----------------------------------------------------------------------------
	//** Get theme path setting **
	themePath : function() 	{
		var path = Env.DIR.CSS_THEME+"/"+Settings.cookie.theme ;
		return path ;
	},

	//-----------------------------------------------------------------------------
	//** Get image path setting **
	imagePath : function() 	{
		var path = Settings.themePath() + "/images" ;
		return path ;
	}

} ;



// Register init routine when doc loaded
$( function() { Settings.init() }  ) ;


