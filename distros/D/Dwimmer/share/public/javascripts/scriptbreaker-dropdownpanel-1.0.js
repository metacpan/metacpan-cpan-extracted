/*
 * jQuery Drop Down panel menu v.1
 * 
 * Copyright (c) 2011 Pieter Pareit
 *
 * http://www.scriptbreaker.com
 *
 */

//plugin definition
(function($){
    $.fn.extend({

    //pass the options variable to the function
    dropDownPanels: function(options) {

		var defaults = {
			speed: 250,
			resetTimer: 1000
		};

		// Extend our default options with those provided.
		var opts = $.extend(defaults, options);
		//Assign current element to variable, in this case is UL element
 		var $this = $(this);

 		var closetimer;
 		
 		function resetMenu(){
 			$this.find(".hover").removeClass("hover");
 			$this.find(".submenu:visible").slideUp(opts.speed);
 		}

 		  function activateTimer(){  
 		      closetimer = window.setTimeout(resetMenu, opts.resetTimer);
 		  }

 		  function cancelTimer(){  
 			    if(closetimer){  
 			 	    window.clearTimeout(closetimer);
 					closetimer = null;
 				}
 			}
 			
 		 $this.find(">li").hover(function() {
 			cancelTimer();
 			if(!$(this).find(".submenu").is(":visible")){
 				$(this).parent().find(".hover").removeClass("hover");
 				$(this).parent().find(".submenu:visible").hide();
 				if($(this).has(".submenu")){
 					$(this).find(".submenu").slideDown(opts.speed);
 					$(this).find("a:first").addClass("hover");
 				}
 			}
 		}, function(){
 			activateTimer();
		});
    }
});
})(jQuery);