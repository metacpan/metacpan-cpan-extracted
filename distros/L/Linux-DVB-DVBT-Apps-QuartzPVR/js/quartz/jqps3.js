////////////////////////////////////////////////////////////
// JQuery "shim" to ensure it works with the PS3 

// Fix toArray()
(function($) {
	$.fn.toArray = function() {
		var list = [];
		this.each(function() {
			list.push(this);
		});
		return list;
	};
})(jQuery);

////////////////////////////////////////////////////////////
// PS3-only
(function($) {
	if (navigator.appName.search(/playstation/i) >= 0)
	{
		//--[ .offset() ]----------------------------------
		$.fn.offset = function() {
			var pos = {
				top 	: 0,
				left	: 0
			};
			
			var obj = this.get(0) ;
			
			/* If the browser supports offsetParent we proceed. */
			if (obj.offsetParent) 
			{
				/* Every time we find a new object, we add its offsetLeft and offsetTop to curleft and curtop. */
				do {
					pos.left += obj.offsetLeft;
					pos.top += obj.offsetTop;
					/*
					The tricky bit: return value of the = operator
					
					Now we get to the tricky bit:
					*/
				} while (obj = obj.offsetParent);
			}
			
			return pos;
		};
		
	}
})(jQuery);
	
	
////////////////////////////////////////////////////////////
