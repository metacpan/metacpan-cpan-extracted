/**
 * Some notes about keys:
 * 
 * For letters:
 *  * keyup and keydown provide accurate keyCode (same regardless of capital/lowercase)
 *  * keypress provides accurate keyChar (the exact character value of the pressed key)
 *  
 * For arrows and other keys:
 *  * keypress is useless cross-browser
 *  * keyup and keydown provide accurate keyCode
 *  ** 8:   Backspace
 *  ** 9:   Tab
 *  ** 13:  Enter
 *  ** 16:  Shift
 *  ** 17:  Control
 *  ** 18:  Alt
 *  ** 19:  Pause
 *  ** 20:  Caps-Lock
 *  ** 27:  Escape
 *  ** 32:  Space
 *  ** 33:  Page-Up
 *  ** 34:  Page-Down
 *  ** 34:  End
 *  ** 36:  Home
 *  ** 37:  Left Arrow
 *  ** 38:  Up Arrow
 *  ** 39:  Right Arrow
 *  ** 40:  Down Arrow
 *  ** 45:  Insert
 *  ** 46:  Delete
 *  ** 91:  Left Window
 *  ** 92:  Right Window
 *  ** 93:  Select
 *  ** 112: F1
 *  ** 113: F2
 *  ** 114: F3
 *  ** 115: F4
 *  ** 116: F5
 *  ** 117: F6
 *  ** 118: F7
 *  ** 119: F8
 *  ** 120: F9
 *  ** 121: F10
 *  ** 122: F11
 *  ** 123: F12
 *  ** 144: Num-Lock
 *  ** 145: Scroll Lock
 *  
 *  NOTE:
 *  * keypress now has full support for keyCode
 *  * keyup now has full support for keyChar
 *  
 */

(function($) {
  function isUndefined(n) { return typeof n == "undefined" }
  function isDefined(n) { return typeof n != "undefined" }
  
  var oldFix = $.event.fix;
  
  $.event.fix = function(event, el) {
    event = oldFix(event);

		var originalEvent = event;
		event = jQuery.extend({}, originalEvent);
		
		event.preventDefault = function() {
			return originalEvent.preventDefault();
		};
    
		event.stopPropagation = function() {
			return originalEvent.stopPropagation();
		};

    // Fix relatedTarget
    if ( isUndefined(event.relatedTarget) && isDefined(event.fromElement) )
      event.relatedTarget = (event.fromElement == event.target) ? event.toElement : event.fromElement;
    
    // Fix currentTarget
    if ( isUndefined(event.currentTarget) )
      event.currentTarget = el;    
    
    // Fix offsetX/offsetY
    if ( isUndefined(event.offsetX) && isDefined(event.pageX) ) {
      var offset = $(event.target).offset(false);
      event.offsetX = event.pageX - offset.left;
      event.offsetY = event.pageY - offset.top;
    }  
      
    // Fix metaKey
    if ( isUndefined(event.metaKey) && isDefined(event.ctrlKey) )
      event.metaKey = event.ctrlKey;
      
    // Add modifiers
    if ( isUndefined(event.modifiers) && isDefined(event.ctrlKey) )
      event.modifiers = (event.altKey ? 1 : 0) + (event.ctrlKey ? 2 : 0) + (event.shiftKey ? 4 : 0);

    // Add AltGraph
    if ( isDefined(event.modifiers) )
      event.altGraph = (event.modifiers & 1 && event.modifiers & 2);
      
    // Add which for click: 1 == left; 2 == middle; 3 == right
    // Note: button is not normalized, so don't use it
    if ( isUndefined(event.which) && isDefined(event.button) )
      event.which = (event.button & 1 ? 1 : ( event.button & 2 ? 3 : ( event.button & 4 ? 2 : 0 ) ));
  
    // Add which for keypresses: keyCode
    if ( (isUndefined(event.which) || event.type == "keypress") && isDefined(event.keyCode) )
      event.which = event.keyCode;
      
    // Add timeStamp if none exists
    if ( isUndefined(event.timeStamp) || event.timeStamp.constructor != Date )
      event.timeStamp = new Date();
      
    // If it's a keypress event, add charCode to IE
    if ( isUndefined(event.charCode) && event.type == "keypress" )
      event.charCode = event.keyCode;
      
    if ( event.type == "keydown" )
      event.currentTarget.keyCode = event.keyCode;
      
    if ( event.type == "keypress" ) {
      event.keyCode = event.currentTarget.keyCode;
      event.currentTarget.keyChar = event.keyChar;
    }
      
    if ( event.type == "keyup" ) {
      event.currentTarget.keyCode = undefined;
      event.keyChar = event.currentTarget.keyChar;
      event.currentTarget.keyChar = undefined; 
    }
      
  	return event;  
  } 
  
  $.event.handle = function(event) {
  	if ( typeof jQuery == "undefined" ) return;
  
  	// Handle the second event of a trigger
  	if ( jQuery.event.triggered ) {
  		jQuery.event.triggered = false;
  		return;
  	}
  
  	// Empty object is for triggered events with no data
  	event = jQuery.event.fix( event || window.event || {}, this ); 
  
  	// returned undefined or false
  	var returnValue;
  
  	var c = this.events[event.type];
  
  	var args = [].slice.call( arguments, 1 );
  	args.unshift( event );
  
  	for ( var j in c ) {
  		// Pass in a reference to the handler function itself
  		// So that we can later remove it
  		args[0].handler = c[j];
  		args[0].data = c[j].data;
  
  		if ( c[j].apply( this, args ) === false ) {
  			event.preventDefault();
  			event.stopPropagation();
  			returnValue = false;
  		}
  	}
  
  	// Clean up added properties in IE to prevent memory leak
  	if (jQuery.browser.msie) event.target = event.preventDefault = event.stopPropagation = event.handler = event.data = null;
  
  	return returnValue;
  }

  var blankFn = function() { };

  $.fn.bind = function( type, data, fn ) {
		return this.each(function(){
			jQuery.event.add( this, type, fn || data, data );
      if(type == "keypress") {
        $(this).bind("keydown", blankFn);
        $(this).bind("keyup", blankFn);
      }
		});
	};
  
	$.fn.unbind = function( type, fn ) {
  	return this.each(function(){
  		jQuery.event.remove( this, type, fn );
      if(type == "keypress") {
        $(this).unbind("keydown", blankFn);
        $(this).unbind("keyup", blankFn);
      }
  	});
  };

})(jQuery);