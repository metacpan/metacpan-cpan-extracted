/*
 * PeriodicalUpdate 0.1 - jQuery plugin to easily update parts of the page <http://gilles.jquery.com/PeriodicalUpdate/>
 *
 * Copyright (c) 2006 Gilles van den Hoven (webunity.nl)
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * v0.1
 *
 * This plugin was inspired by the jHearthbeat plugin of Jason Levine (http://www.jasons-toolbox.com)
 *
 * Settings can be the following:
 * - url				URL to call
 * - delay			Delay of the update
 * - delayed		If we have to wait untill the data is loaded before staring a new cycle
 * - cbStart		Callback before the element is updated
 * - cbFinish		Callback after the element is updated
 */
(function($) {
	// save reference to plugin method
	var plugin = $.fn.PeriodicalUpdate = function(settings) {
		settings = $.extend({}, arguments.callee.defaults, settings);

		// Initialize
		var container=this;

		//
		// Start function
		container.puTimer = -1;
		container.puStart = function() {
			container.puTimer = setTimeout(container.puTick, settings.delay);
		};

		//
		// Tick function
		container.puTick = function() {
			//
			// Callback?
			if (settings.cbStart && (settings.cbStart.constructor == Function)) {
				settings.cbStart($(container));
			}

			// Clear timer?
			if (container.puTimer != -1) {
				container.puStop();
			}

			//
			// Reset timer?
			if (!settings.delayed) {
				container.puStart();
			}

			//
			// Load new content
			container.load(settings.url, function() {
					//
					// Callback?
					if (settings.cbFinish && (settings.cbFinish.constructor == Function)) {
						settings.cbFinish($(container));
					}

					//
					// Reset timer?
					if (settings.delayed) {
						container.puStart();
					}
				});
		};

		//
		// Stop function
		container.puStop = function() {
			clearTimeout(container.puTimer);
			container.puTimer = -1;
		};

		//
		// Start timer, and fire first event
		container.puTick();

		//
		// ready
		return container;
	};

	// define global defaults, editable by client
	plugin.defaults = {
		url: '',
		delay: 1000,
		delayed: false,
		cbStart: null,
		cbFinish: null
	};

})(jQuery);
