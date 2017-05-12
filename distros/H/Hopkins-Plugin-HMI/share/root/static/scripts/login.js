(function() {
	evtLoaded.subscribe(function() {
		var button = new YAHOO.widget.Button('button_login');

		button.subscribe('click', onLoginClick);
	});

	function onLoginClick()
	{
		YAHOO.util.Dom.get('login').submit();
	}
})();
