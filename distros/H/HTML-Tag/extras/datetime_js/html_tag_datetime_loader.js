/* Javascript Loader for HTML::Tag::Date and HTML::Tag::Datetime */

var html_tag_datetime_loaded;
if (!html_tag_datetime_loaded) {
	html_tag_datetime_loaded = 1;
	with (document) {
		writeln('<style type="text/css">@import url(' + scriptPath() + 'jscalendar/skins/aqua/theme.css);</style>');
		writeln('<script type="text/javascript" src="' + scriptPath() + 'jscalendar/calendar.js"></script>');
		writeln('<script type="text/javascript" src="' + scriptPath() + 'jscalendar/lang/calendar-it.js"></script>');
		writeln('<script type="text/javascript" src="' + scriptPath() + 'jscalendar/calendar-setup.js"></script>');
		writeln('<script type="text/javascript" src="' + scriptPath() + 'validator.js"></script>');
		writeln('<script type="text/javascript" src="' + scriptPath() + 'html_tag_datetime.js"></script>');
	}
}

function scriptPath()  {
	var script_name = 'html_tag_datetime_loader.js';
	// optimized :-D
	var scripts = document.getElementsByTagName("SCRIPT");
	var script_name_len = script_name.length;
	for (i=0; i< scripts.length; i++) {
		var script = scripts[i].src;
		if (script.slice(script.length-script_name_len,script.length) ==
			script_name) {
			var script_url = script;
			if (script_url.slice(0,4) != 'http') {
				// build as an absolute url (IE hack)
				var loc = document.location;
				script_url = loc.protocol + '//' + loc.host;
				if (script.slice(0,1) == "/") {
					// absolute path
					script_url += script;
				} else {
					// relative path
					script_url += loc.pathname;
					script_url = script_url.slice(0,script_url.lastIndexOf('/'));
					script_url = script_url + '/' + script;
				}
			}
			return script_url.slice(0,script_url.length-script_name_len);
		}
	}
}
