/*
 * JHeartbeat 0.1.1 Beta
 * By Jason Levine (http://www.jasons-toolbox.com)
 * A heartbeat plugin for the jquery library to help keep sessions alive.
 */
 
 $.jheartbeat = {

    options: {
		url: "heartbeat_default.asp",
		counter: 0,
		delay: 10000
    },
	
	beatfunction:  function(){
	
	},
	
	timeoutobj:  {
		id: -1
	},

    set: function(options, onbeatfunction) {
		if (this.timeoutobj.id > -1) {
			clearTimeout(this.timeoutobj);
		}
        if (options) {
            $.extend(this.options, options);
        }
        if (onbeatfunction) {
            this.beatfunction = onbeatfunction;
        }

		// Add the HeartBeatDIV to the page
		$("body").append("<div id=\"HeartBeatDIV\" style=\"display: none;\"></div>");
		this.timeoutobj.id = setTimeout("$.jheartbeat.beat();", this.options.delay);
    },

    beat: function() {
                var c = this.options.url.search(/\?/) == -1 ? '?' : '&' ; 
		var newUrl = this.options.url + c + "counter=" + this.options.counter++ ; 
		$("#HeartBeatDIV").load(newUrl);
		this.timeoutobj.id = setTimeout("$.jheartbeat.beat();", this.options.delay);
        this.beatfunction();
    }
};
