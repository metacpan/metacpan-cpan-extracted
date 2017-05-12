if(window.widget) {
  widget.getPref   = widget.preferenceForKey;
  widget.setPref   = widget.getPreferenceForKey;
  widget.clearPref = function(pref) { widget.setPref(pref, null) }
  window.open      = widget.openURL;
  window.runSync   = function(command, callBack) { s = widget.system(command, NULL); callBack(s.outputString, s.errorString, s.status) }
  window.runAsync  = function(command, callBack, stdout, stderr) {
    s = widget.system(command, callBack);
    s.onreadoutput = stdout;
    s.onreaderror  = stderr;
    return s;
  };
}

/**
 * Flips from one side to another.
 * 
 * @param String expr A jQuery expression whose first element is the side to flip to
 * @example $("#front").flipTo("#back")
 * @before <div id="front" style="display: block">Stuff on the Front</div><div id="back" style="display: none">Stuff on the back</div>
 * @after <div id="front" style="display: none">Stuff on the Front</div><div id="back" style="display: block">Stuff on the back</div>
 * @name flipTo
 * @type void
 * @cat Plugins/AppleWidgets
 * @author Yehuda Katz <wycats@gmail.com>
 */

jQuery.fn.flipTo = function(expr) {
  var other = jQuery(expr);
  if(typeof widget != "undefined") widget.prepareForTransition("ToBack");
  this.hide();
  other.show();
  if(typeof widget != "undefined") setTimeout("widget.performTransition()", 0);
};

/**
 * Converts the first element in a jQuery object into a vertical scroll bar.
 * 
 * @param jScrollArea area An instantiated AppleScrollArea (you can use $.fn.scrollArea)
 * @param Object options A hash of options
 * @option Number minThumbSize The smallest scroller thumb size allowed
 * @option Number padding The padding on the scroll bar
 * @option Boolean autohide True if the scroll bar should not be present if there is no scrollable content
 * @example $("#vert").verticalScrollbarFor(area, { autoHide: true })
 * @example $("<div></div>").verticalScrollbarFor(area)
 * @name verticalScrollbarFor
 * @type jScrollArea
 * @cat Plugins/AppleWidgets
 * @author Yehuda Katz <wycats@gmail.com>
 */

jQuery.fn.verticalScrollbarFor = function(area, options) {
  scrollbar = jVerticalScrollbar(this[0], options);
  area.addScrollbar(scrollbar)
  return area;
};

/**
 * Converts the first element in a jQuery object into a horizontal scroll bar.
 * 
 * @param jScrollArea area An instantiated AppleScrollArea (you can use $.fn.scrollArea)
 * @param Object options A hash of options
 * @option Number minThumbSize The smallest scroller thumb size allowed
 * @option Number padding The padding on the scroll bar
 * @option Boolean autohide True if the scroll bar should not be present if there is no scrollable content
 * @example $("#horiz").horizontalScrollbarFor(area, { autoHide: true })
 * @example $("<div></div>").horizontalScrollbarFor(area)
 * @name horizontalScrollbarFor
 * @type jScrollArea
 * @cat Plugins/AppleWidgets
 * @author Yehuda Katz <wycats@gmail.com>
 */

jQuery.fn.horizontalScrollbarFor = function(area, options) {
  scrollbar = jHorizontalScrollbar(this[0], options);
  area.addScrollbar(scrollbar);
  return area;
};

/**
 * Converts the first element in a jQuery object into an AppleScrollArea
 * 
 * @param Object options A hash of options
 * @example $("#area").scrollArea({ scrollsVertically: false })
 * @name makeScrollArea
 * @type jScrollArea
 * @cat Plugins/AppleWidgets
 * @author Yehuda Katz <wycats@gmail.com>
 */

jQuery.fn.makeScrollArea = function(options) {
  return jScrollArea(this[0], options)
};

/**
 * Creates a jScrollArea with scroll bars
 * 
 * @option Number minThumbSize The smallest scroller thumb size allowed
 * @option Number padding The padding on the scroll bar
 * @option Boolean autohide True if the scroll bar should not be present if there is no scrollable content
 * @type jScrollArea
 * @example $("#area").makeScrollArea
 */

jQuery.fn.makeScrollAreaWithBars = function(options, vertAttrs, horizAttrs) {
  area = this.makeScrollArea(options);
  var jContent = $(area.content)
  var offset = jContent.offset();
  if(vertAttrs) { 
    jQuery("<div class='vertical-bar'></div>").attr(vertAttrs || {}).appendTo(jContent.parent())
      .css({height: jContent.height() + "px", top: offset.top + "px", left: jContent.width() + offset.left + "px"})
      .verticalScrollbarFor(area);
  }
  if(horizAttrs) {
    jQuery("<div class='horizontal-bar'></div>").attr(horizAttrs || {}).appendTo(jContent.parent())
      .css({width: jContent.width() + "px", left: offset.left + "px", top: jContent.height() + offset.top + "px"})
      .horizontalScrollbarFor(area);
  }
  
  return area;
};

/**
 * @private
 * @param Element bar The new scrollbar
 * @param String type "horizontal" or "vertical"
 */

barProperties = function(bar, type) {
  return {
    track: function() { return this._track },
    thumb: function() { return this._thumb },
    toggleAutohide: function() { this.setAutohide(!this.autohide); },
    toggle: function() { if(this.hidden) this.show(); else this.hide() },
    _verticalHasScrolled: bar.verticalHasScrolled,
    verticalHasScrolled: function() { 
      this._verticalHasScrolled(); this.scrollarea.onverticalchange && this.scrollarea.onverticalchange(this.scrollarea.topPercent()); 
    },
    _horizontalHasScrolled: bar.verticalHasScrolled,
    horizontalHasScrolled: function() { 
      this._horizontalHasScrolled(); this.scrollarea.onhorizontalchange && this.scrollarea.onhorizontalchange(this.scrollarea.leftPercent()); 
    },    
    type: type
  }
}

/**
 * Creates a new horizontal scrollbar, extended with additional properties
 * 
 * @param Element bar The new scrollbar
 * @param Object options a hash of options for the jHorizontalScrollbar
 */

var jHorizontalScrollbar = function(bar, options) {
  bar = jQuery.extend(new AppleHorizontalScrollbar(bar), options);
  return jQuery.extend(bar, barProperties(bar, "horizontal"));
}

/**
 * Creates a new vertical scrollbar, extended with additional properties
 * 
 * @param Element bar The new scrollbar
 * @param Object options a hash of options for the jVerticalScrollbar
 */

var jVerticalScrollbar = function(bar, options) {
  bar = jQuery.extend(new AppleVerticalScrollbar(bar), options);
  return jQuery.extend(bar, barProperties(bar, "vertical"));
}

/**
 * The jScrollArea inherits properties and methods from AppleScrollArea
 * 
 * * '''scrollsVertically:''' determines if the area scrolls vertically (read/write)
 * * '''scrollsHorizontally:''' determines if the area scrolls horizontally (read/write)
 * * '''singlepressScrollPixels:''' the number of pixels the scroll area scrolls when an arrow key is pressed (read/write)
 * * '''viewHeight:''' the height of the scroll area (read-only)
 * * '''viewToContentHeightRatio:''' the ratio of the height of the view versus the total amount of content shown (read-only)
 * * '''viewWidth:''' the width of the scroll area (read-only)
 * * '''viewToContentWidthRatio:''' the ratio of the width of the view versus the total amount of content shown (read-only)
 * * '''scrollbars:''' a list of the scrollbars attached to the scroll area (undocumented)
 * * '''addScrollBar(scrollbar):''' associates a scroll bar with a scroll area
 * * '''removeScrollbar(scrollbar):''' disassociates a scroll bar and a scroll area
 * * '''remove():''' removes a scroll area from the widget
 * * '''refresh():''' redraws the scroll area's scroll bars; call whenever a content change happens
 * * '''reveal(element):''' Accepts a DOM element; scrolls the view to make the element visible
 * * '''focus():''' Gives the scroll area focus (and responds to key events)
 * * '''blur():''' Removes focus from the scroll area (and no longer responds to key events)
 * * '''verticalScrollTo(position):''' Accepts an integer; moves the content within the scroll area to 'position'
 * * '''horizontalScrollTo(position):'''  Accepts an integer; moves the content within the scroll area to 'position'
 * 
 * It also adds new methods:
 * * '''bind(fn):''' Applies jQuery's bind method to the content inside the scroll area
 * * '''unbind(fn):''' Applies jQuery's unbind method to the the content inside the scroll area
 * * '''one(fn):''' Applies jQuery's one method to the the content inside the scroll area
 * * '''trigger(fn):''' Applies jQuery's trigger method to the the content inside the scroll area
 * * '''contentWidth():''' Provides the current width of the content area
 * * '''contentHeight():''' Provides the current height of the content area
 * * '''topPercent():''' The percentage that the scrollArea is scrolled from the top
 * * '''leftPercent():''' The percentage that the scrollArea is scrolled from the left
 * * '''verticalChange(fn):''' This callback will be fired when when a vertical change occurs in the scrollArea
 * * '''horizontalChange(fn):''' This callback will be fired when when a horizontal change occurs in the scrollArea
 * 
 * It also adds new properies:
 * * onverticalchange: A function called when the scrollArea changes vertically. It is passed topPercent() as a parameter
 * * onhorizontalchange: A function called when the scrollArea changes vertically. It is passed leftPercent() as a parameter
 * 
 * @param Element area The DOM Element that will become the jScrollArea
 * @param Object options A hash of options for the jScrollArea
 */

var jScrollArea = function(area, options) {
  area = jQuery.extend(new AppleScrollArea(area), options);
  return jQuery.extend(area, {
    bind: function(type, fn) { jQuery(this.content).bind(type, fn); return this; },
    unbind: function(type, fn) { jQuery(this.content).unbind(type, fn); return this; },
    one: function(type, fn) { jQuery(this.content).one(type, fn); return this; },
    trigger: function(type) { jQuery(this.content).trigger(type); return this; },
    scrollbars: function() { return this._scrollbars },
    horizontalScrollbar: function() { return jQuery.map(this._scrollbars, function(i) { return (i.type == "horizontal") ? i : undefined })[0] },
    verticalScrollbar: function() { return jQuery.map(this._scrollbars, function(i) { return (i.type == "vertical") ? i : undefined })[0] },
    contentHeight: function() { return this.viewHeight / this.viewToContentHeightRatio },
    contentWidth: function() { return this.viewWidth / this.viewToContentWidthRatio },
    topPercent: function() { return (this.content.scrollTop / (this.contentHeight() - this.viewHeight)) },
    leftPercent: function() { return (this.content.scrollLeft / (this.contentWidth() - this.viewWidth)) },
    horizontalChange: function(fn) { this.onhorizontalchange = fn; return this; },
    verticalChange: function(fn) { this.onverticalchange = fn; return this; }
  })
}

/**
 * Creates an AppleGlassButton extended with various additional functions
 *
 * The button is extended with bind, unbind, one, and trigger, which act on the DOM element the button object represents.
 * 
 * It is also extended with a click method, which is used exactly like jQuery's click, except that it operates on the 
 * jGlassButton object itself, and not the underlying DOM element.
 * 
 * If you want to bind a click event to the DOM Element, use .bind("click", fn)
 * 
 * @param Element button An element containing the element to convert into a button
 * @param Object options Additional options to extend the button with (pass in a label option to set the label)
 * @example jGlassButton($("#button"), {label: $("#button").html()})
 * 
 */

var jGlassButton = function(button, options) {
  $(button).html("");
  var button = jQuery.extend(new AppleGlassButton(button, options.label), options);
  return jQuery.extend(button, {
    click: function(fn) { if(fn) this.onclick = fn; else this.onclick(); return this; },
    bind: function(type, fn) { jQuery(this.button()).bind(type, fn); return this.button; },
    unbind: function(type, fn) { jQuery(this.button()).unbind(type, fn); return this.button; },
    one: function(type, fn) { jQuery(this.button()).one(type, fn); return this.button; },
    trigger: function(type) { jQuery(this.button()).trigger(type); return this.button; },
    button: function() { return this._container.parentNode; }
  });
};

/**
 * Creates a jGlassButton from the matched elements in the jQuery object
 * 
 * @param Object options a hash of options to pass jGlassButton
 * @type Array<jGlassButton> An array of jGlassButton objects
 * @example $("button").jGlassButton()
 */

jQuery.fn.makeGlassButton = function(options) {
  return jQuery.extend(jQuery.map(this, function(i) { 
    return jGlassButton(i, jQuery.extend(options || {}, {label: i.innerHTML}));
  }));
}

var jSlider = function(type, size, attrs, appendTo) {
  if(type == "horizontal")
    slider = new AppleHorizontalSlider($("<div></div>").attr(attrs).appendTo(appendTo).css("width", size + "px")[0]);
  else
    slider = new AppleVerticalSlider($("<div></div>").attr(attrs).appendTo(appendTo).css("height", size + "px")[0]);
  return jQuery.extend(slider, {
    size: size,
    change: function(fnVal) { 
      this.onchanged = fnVal; 
      return this;
    }
  })
} 