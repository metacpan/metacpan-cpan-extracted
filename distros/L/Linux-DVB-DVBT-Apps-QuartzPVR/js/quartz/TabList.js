/*
Tabbed list

Manage a tabbed list of elements. A tab of "pages" is shown at the top, with the corresponding "page" 
shown underneath:

    ________   ________   ________
___| page 1 |_|_Page_2_|_|_Page_3_|___________________

Page 1 contents...


The HTML is in the form:

	<ul class="xxxx">
		<li class="yyy">
			DVB-T
		</li>
		<li class="yyy sel">
			IPLAY
		</li>
		<li class="yyy">
			IPLAY + DVB-T
		</li>
		<li class="yyy">
			Fuzzy
		</li>
	</ul>
	<node class="zzz tab1">
		.. page 1 
	</node>
	<node class="zzz tab2">
		.. page 2
	</node>

i.e. the tab menu is an <ul> with the selected tab item having the class "sel". Each page node is marked
with "tab1" etc.

The CSS to show the correct tabbing etc is of the form:

	// background for this example is black
	.xxxx {
		margin: 1em 0.1em ;
		display: block ;
	    border-bottom: 1px solid white ;
	    padding: 2px 5px ;
	}
	
	// set un-selected "tabs" to show as white boxes with black text
	.xxxx li.yyy {
	    border: 1px solid white ;
	    color: black ;
	    background: white ;
	    display: inline ;
	    padding: 2px 5px ;
	    
	    // tab separator
	    margin: 0 0 0 5px ;
	}
	
	// invert selected tab
	.xxxx li.sel {
	    border-bottom: 1px solid black ;
	    color: white ;
	    background: black ;
	}

This object creates the "tab" <ul> based on the list given

*/



//=======================================================================================================
// Constructor
//=======================================================================================================
function TabList(tabClass, tabItemClass, tabs)
{
	this.tabClass = tabClass ;
	this.tabItemClass = tabItemClass ;
	this.selected = 0 ;
	this.tabs = [] ;
	this.tabItems = [] ;
	this.pages = [] ;
	
	if (tabs)
	{
		this.setTabs(tabs) ;
	}
}

//=======================================================================================================
// CLASS
//=======================================================================================================


//=======================================================================================================
// OBJECT
//=======================================================================================================

//-------------------------------------------------------------------------------------------------------
// Set the tab menu items. tabs is an array of text entries
TabList.prototype.setTabs = function(tabs)
{
	this.tabs = [] ;
	for (var i=0; i < tabs.length; i++)
	{
		this.tabs[i] = tabs[i] ;
	}
	this.selected = 0 ;
}

//-------------------------------------------------------------------------------------------------------
//Set the page contents
TabList.prototype.setPage = function(pageIndex, pageDom)
{
	pageIndex -= 1 ;
	if ( (pageIndex >= 0) && (pageIndex < this.tabs.length) )
	{
		this.pages[pageIndex] = pageDom ;
	}
}

//-------------------------------------------------------------------------------------------------------
//Set the page to be shown first
TabList.prototype.activePage = function(pageIndex)
{
	pageIndex -= 1 ;
	if ( (pageIndex >= 0) && (pageIndex < this.tabs.length) )
	{
		this.selected = pageIndex ;
	}
}


//-------------------------------------------------------------------------------------------------------
// Add the tabbed menu elements to a DOM node
TabList.prototype.createDom = function(node)
{
	// Tabbed Menu
	//
	//	<ul class="xxxx">
	//		<li class="yyy">
	//			DVB-T
	//		</li>
	//		<li class="yyy sel">
	//			IPLAY
	//		</li>
	//		<li class="yyy">
	//			IPLAY + DVB-T
	//		</li>
	//		<li class="yyy">
	//			Fuzzy
	//		</li>
	//	</ul>
	var ul = document.createElement("ul");
	ul.className = this.tabClass ;
	node.appendChild(ul) ;
	
	for (var i=0; i < this.tabs.length; i++)
	{
		var li = document.createElement("li");
		this.tabItems[i] = li ;
		var className = this.tabItemClass ;
		if (i == this.selected)
		{
			className = className + ' ' + 'sel' ;
		}
		li.className = className ;
		ul.appendChild(li) ;

			var a = document.createElement("a");
			li.appendChild(a) ;
			a.appendChild(document.createTextNode(this.tabs[i])) ;
			
			// add switch handler
//			if (i != this.selected)
//			{
				// set handler
				function create_show_handler(tabList, tabIdx) {
					return function() {

						// Clear "selected" tab
						var reSel = new RegExp('\\bsel\\b');
						for (var i=0; i < tabList.tabs.length; i++)
						{
							var cname = tabList.tabItems[i].className ;
							if(reSel.test(cname))
							{
								// remove it
								tabList.tabItems[i].className = cname.replace(reSel, "") ;
							}
						}
						
						// set selected
						tabList.tabItems[tabIdx].className += ' sel' ;

						
						// Hide pages
						for (var i=0; i < tabList.pages.length; i++)
						{
							tabList.pages[i].style.display = 'none' ;
						}
						
						// set selected
						tabList.pages[tabIdx].style.display = 'block' ;

					};
				} 
				$(a).click(create_show_handler(this, i)) ; 

	}
	
	
	// Pages
	//
	var re = new RegExp('\\btab\\d\\b');
	for (var i=0; i < this.tabs.length; i++)
	{
		var dom = null ;
		if (i < this.pages.length)
		{
			dom = this.pages[i] ;
		}
		if (!dom)
		{
			dom = document.createElement("div");
			this.pages[i] = dom ;
		}
		
		// check for existing "tab" classname
		var cname = dom.className ;
		if(re.test(cname))
		{
			// remove it
			cname = cname.replace(re, "") ;
		}
		cname = cname + ' ' + 'tab' + (i+1) ;
		dom.className = cname ;
		
		// add to parent
		node.appendChild(dom) ;
		
		// if this is not selected then hide it
		if (i == this.selected)
		{
			dom.style.display = 'block' ;
		}
		else
		{
			dom.style.display = 'none' ;
		}
	}
}


