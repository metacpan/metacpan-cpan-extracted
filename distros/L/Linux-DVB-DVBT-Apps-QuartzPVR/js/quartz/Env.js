/* Client environment */

var Env = {} ;

// Browser type
Env.BROWSER = {
	PS3 : false,
	PSP : false,
	Android : false,
	Other : false
} ;

Env.browser=navigator.appName;
Env.browserUa=navigator.userAgent;
if (Env.browser.search(/playstation/i) >= 0)
{
	Env.BROWSER.PS3 = true ;
}
else if (Env.browser.search(/psp/i) >= 0)
{
	Env.BROWSER.PSP = true ;
}
else if (Env.browserUa.search(/Android/i) >= 0)
{
	Env.BROWSER.Android = true ;
}
else
{
	Env.BROWSER.Other = true ;
}

//// DEBUG
//Env.BROWSER.PS3 = true ;


Env.screenSize = function()
{
	// Screen size
	Env.SCREEN_WIDTH = screen.width ;
	Env.SCREEN_HEIGHT = screen.height ;
	
	if( typeof( window.innerWidth ) == 'number' ) 
	{
		Env.SCREEN_WIDTH = window.innerWidth; 
		Env.SCREEN_HEIGHT = window.innerHeight;
	} 
	else if( document.documentElement && ( document.documentElement.clientWidth ||document.documentElement.clientHeight ) ) 
	{
		Env.SCREEN_WIDTH = document.documentElement.clientWidth; 
		Env.SCREEN_HEIGHT = document.documentElement.clientHeight;
	} 
	else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) 
	{
		Env.SCREEN_WIDTH = document.body.clientWidth; 
		Env.SCREEN_HEIGHT = document.body.clientHeight;
	}
}
Env.screenSize() ;

// Directories
Env.DIR = {
	CSS 		: 'css',
	CSS_THEME 	: 'css/theme' 
} ;
