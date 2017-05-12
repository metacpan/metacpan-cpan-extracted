/*
 * Format 1.0 - jQuery plugin to add printf-like capabilites to jQuery methods
 *
 * Copyright (c) 2007 Jörn Zaefferer
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Revision: $Id: jquery.format.js 1495 2007-03-06 20:49:08Z joern $
 *
 */

/**
 * Extends jQuery's built-in html method to accept additional
 * arguments and use them to replace any percent-signs found in the
 * html string.
 *
 * @example jQuery("div").html("Hi <strong>%</strong> in the year %?", name, new Date().getYear() + 1900);
 * @result [ <div>Hi <strong>Peter</strong> in the year 2007?</div> ]
 * @desc Basic usage example
 *
 * @example jQuery("div").html("% %% done.", 56);
 * @result [ <div>56 % done.</div> ]
 * @desc Escaping of placeholder
 *
 * @param String html The HTML to set and format
 * @param String [...] Any number of arguments to place into the HTML
 * @type String
 * @name html
 * @cat Plugins/Format
 */

/**
 * Extends jQuery's built-in text method to accept additional
 * arguments and use them to replace any percent-signs found in the
 * text string.
 *
 * @example jQuery("div").text("Hi <strong>%</strong> in the year %?", "Peter", new Date().getYear() + 1900);
 * @result [ <div>Hi &lt;strong&gt;Peter&lt;/strong&gt; in the year 2007?</div> ]
 * @desc Basic usage example
 *
 * @example jQuery("div").text("% %% done.", 56);
 * @result [ <div>56 % done.</div> ]
 * @desc Escaping of placeholder
 *
 * @param String text The text to set and format
 * @param String [...] Any number of arguments to place into the text
 * @type String
 * @name text
 * @cat Plugins/Format
 */
 
/**
 * The formatter used by extended text() and html(). It replaces all
 * placeholders found in the first argument by the elements of the array from the
 * second argument. Would be the base to extend other HTML transforming methods
 * as append().
 *
 * @param String value A template, containing percent-characters to indicate placeholders
 * @param Array<String> [...] An array of strings to replace the placeholders with
 * @type String
 * @name jQuery.format
 * @cat Plugins/Format
 */
 

(function($) {
	
	function replace(handler, args) {
		return handler.apply(this, args.length < 2 ? args : [$.format(args[0], $.makeArray(args).slice(1))]);
	}
	
	var oldhtml = $.fn.html,
		oldtext = $.fn.text;
	
	$.fn.extend({
		html: function() {
			return replace.call(this, oldhtml, arguments);
		},
		text: function(text) {
			return replace.call(this, oldtext, arguments);
		}
	});
	
	$.format = function(value, args) {
		var counter = 0;
		return value.replace(/%/g, function(char, pos, value) {
			var before = value.charAt(pos - 1),
				after = value.charAt(pos + 1);
			if( before == "%" )
				return "%";
			if( after == "%" )
				return "";
			return args[counter++]
		});
	}

})(jQuery);