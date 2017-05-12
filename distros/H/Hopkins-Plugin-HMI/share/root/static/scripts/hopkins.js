var evtLoaded = new YAHOO.util.CustomEvent('onloader', this);

var loader = new YAHOO.util.YUILoader({
	base:			'/static/yui/build/',
	require:		yuireq,
	loadOptional:	false,
	filter:			'MIN',
	allowRollup:	true,
	onSuccess:		function()
	{
		evtLoaded.fire({});
	}
});

//YAHOO.addInputExModules(loader, 'static/inputex/');

loader.insert();

