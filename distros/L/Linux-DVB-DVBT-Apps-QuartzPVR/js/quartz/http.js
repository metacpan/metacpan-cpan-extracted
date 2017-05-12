// Migrate to JQuery
var HTTP = {};

HTTP.get = function(url, callback, options) {

	// Actually use POST request since HTTP specifies that:
	// * GET is for non-changing data (i.e. can be cached)
	// * POST is for changeable data
	//
	$.ajaxSetup({
		timeout:	options.timeout,
		dataType:	'json',
		error:		options.errorHandler,
		cache:		false
	}) ;
	
	//$.post(url, options.parameters, callback) ;
	$.get(url, options.parameters, callback) ;
};

