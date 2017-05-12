jQuery.prop = function( elem, key, value, type ){
	// TODO: Make this useful
	var val = '';
			
	// Handle executable functions
	return value.constructor == Function &&
		value.call( elem, val ) ||
		
		// Handle parsed string content
		value.constructor == String &&
		value.replace(/\${(.*?)}/g, function(a,m){
			return (new Function("old","num","return " + m))
				.call( elem, val, parseFloat( val ) );
		}) ||
				
		// Handle everything else
		value;
};
