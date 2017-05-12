/*
 * autoSave: Pain free automatic updates via ajax
 *
 * Version 1.1
 *
 * Copyright (c) 2007 Daemach (John Wilson) <daemach@gmail.com>, http://ideamill.synaptrixgroup.com
 * Licensed under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 * 
 * Includes: createCSSClass function by Sam Collett
 * See below for full credit information
 *
 * Special thanks to Blair Mitchelmore for patiently explaining closures :)
 *
 * ============================================================================================
 * Usage:  $("yourFormInputs").autoSave( Function, Map )     
 * 
 * Function: any ajax function.  The function is called in the scope of the element itself
 * so "this" refers to the element's properties: this.id, this.value, this.checked, etc.
 *
 * Map: key value pairs as parameters 
 *    delay(ms) - for text fields, how long to wait before posting.  default 1000ms
 *    beforeClass - class to apply to the element when the value has changed
 *    afterClass - class to apply to the element after the ajax call has returned
 *    onChange - function to run when the value changes.  By default applies beforeClass
 *    preSave - function to run just before the ajax function is run.  Returning a boolean 
 *              "false" from this function will prevent the ajax call from running and reverts 
 *              the field to its previous value.  All other return values allow the ajax call
 *              to run normally. ( Of limited use, but why not... )
 *
 *              ex: { preSave : function (){ return confirm('are you sure?'); } }
 *             
 *    postSave - function to run when the ajax call completes.  By default applies afterClass
 *
 * Caveats: Checkboxes have to be handled specially since they don't have separate values for 
 *          checked and unchecked states.  See below for one possible solution.
 *  
 * Example: 
 *
 *		$(document).ready(function(){
 *			$(":input").autoSave(function(){
 *				var ele = new Object();
 * 
 *				// remember that this function runs in the scope of the element itself.
 *				ele[this.name] = (this.type =="checkbox") ? this.value + "|" + this.checked : this.value;
 *				$.post("test.cfm", ele, function (data) {$("#ResultDiv").empty().append(data);} )
 *			});
 *		});
 *
 */

jQuery.fn.autoSave = function (fcn, settings) {
    $daemach = (typeof $daemach !== "undefined") ? $daemach : {};
    if (typeof $daemach.autoSave == "undefined") {
        $daemach.autoSave =  new Object();
        $daemach.autoSave["timer"] =  new Array();
        $daemach.autoSave["fn"] =  new Array();
    }
	 
	 var _as = $daemach.autoSave;
	 
    settings = jQuery.extend( {
        delay : 500,
		  doClassChange: true,
		  beforeClass : "asBefore", 
		  afterClass : "asAfter", 
		  onChange: null, 
		  preSave : null,
		  postSave : null,
		  minLength: 0
		  
    }
    , settings);
	 
	 if (settings.doClassChange){
	 	if (settings.beforeClass == "asBefore") { createCSSClass(".asBefore", "background-color:#FFdddd"); }
    	if (settings.afterClass == "asAfter") { createCSSClass(".asAfter", "background-color:#ddFFdd"); }
	 }
	 // Start building...
    return this.each(function () {
        var p = this.name;
        if (typeof  _as["fn"][p] == "undefined") {
            _as["fn"][p] =  new Array();
            _as["fn"][p][0] = null;
        }
        var bindType;
        var initialState;
        switch (this.type) {
            case "text":
                bindType = "keyup";
                 initialState = this.value;
                break;
            case "hidden":
                bindType = "keyup";
                 initialState = this.value;
                break;
            case "textarea":
                bindType = "keyup";
                 initialState = this.value;
                break;
            case "password":
                bindType = "keyup";
                 initialState = this.value;
                break;
            case "select-one":
                bindType = "change";
                 initialState = this.value;
                break;
            case "select-multiple":
                bindType = "change";
                 initialState = this.value;
                break;
            case "radio":
                bindType = "click";
                 initialState = this.value;
                break;
            case "checkbox":
                bindType = "click";
                 initialState = this.checked;
                break;
                default  : bindType = "keyup";
                 initialState = this.value;
                break;
        }
        if (bindType == "keyup") {
             _as["timer"][p] = null;
        }
        if (this.type !== "radio" || (this.type == "radio" && this.checked)) {
             _as["fn"][p][0] =  initialState;
        }
         _as["fn"][p][1] = function (e) {
            if (e && e.type == 'blur' &&  _as["fn"][p][2]) {
                if ( _as["timer"][p]) window.clearTimeout( _as["timer"][p]);
            }
				// check lock in case settings.onChange function contained something that caused the blur element to fire
				if ( _as["fn"][p][2]){
					if ( _as["fn"][p][0] !== this.value || (this.type == "checkbox")) {
						
						if (settings.preSave) {
							// lock again for preSave function
							 _as["fn"][p][2] = false;
							
							var proceed = settings.preSave.apply(this);
							if (!(typeof proceed == "boolean" && proceed == false)){
								 _as["fn"][p][2] = true;
							}
						}
						
						if ( _as["fn"][p][2]){
							 // call the main function
							 fcn.apply(this); 
							 // record new state
							  _as["fn"][p][0] = this.value;
						} else {
							// revert 
							if (this.type == "checkbox"){
								this.checked =  _as["fn"][p][0];
							} else {
								this.value =  _as["fn"][p][0];
							}
						}
						 //run post save function
						 if (settings.postSave) {
							  settings.postSave.apply(this);
						 }
						 
						 if (settings.doClassChange) {
							jQuery(this).removeClass(settings.beforeClass).addClass(settings.afterClass);
						 }
					}
				}
        }
		  // init locking mechanism
		   _as["fn"][p][2] = true;
		  
        jQuery(this).bind(bindType, function () {
            if ( _as["fn"][p][0] !== this.value || (this.type == "checkbox")) {
                if (settings.onChange) {
						// lock handler in case onChange function causes this field to lose focus
						 _as["fn"][p][2] = false;
						
						var proceed = settings.onChange.apply(this);
						if (!(typeof proceed == "boolean" && proceed == false)){
							 _as["fn"][p][2] = true;
						}
                }
					 if (settings.doClassChange) {
						var ele = jQuery(this);
						if (ele.is('.' + settings.afterClass))ele.removeClass(settings.afterClass);
						if (!ele.is('.' + settings.beforeClass))ele.addClass(settings.beforeClass); 
					 }

                var me = this;
                if (bindType == "keyup") {
						 if (this.value.length >= settings.minLength){
                    	 _as["timer"][p] = window.setTimeout(function () { _as["fn"][p][1].apply(me);}, settings.delay);
						 }
                }
                else {
                     _as["fn"][p][1].apply(me);
                }
            }
        }
        );
        if (bindType == "keyup") {
            jQuery(this).blur(function(){ if (this.value.length  >= settings.minLength){  _as["fn"][p][1] } });
        }
        if (bindType == "keyup") {
            jQuery(this).keydown(function () {
                if ( _as["timer"][p]){ window.clearTimeout( _as["timer"][p]) };
            }
            );
        }
    }
    );
};

if (typeof createCSSClass == "undefined") {
    function createCSSClass(selector, style) {
        // Created by Sam Collett - 2007
        // http://webdevel.blogspot.com/2006/06/create-css-class-javascript.html
        //
        // using information found at: http://www.quirksmode.org/dom/w3c_css.html
        // doesn't work in older versions of Opera (< 9) due to lack of styleSheets support
        if (!document.styleSheets)return;
        if (document.getElementsByTagName("head").length == 0)return;
        var stylesheet;
        var mediaType;
        if (document.styleSheets.length > 0) {
            for (var i = 0; i < document.styleSheets.length; i++) {
                if (document.styleSheets[i].disabled)continue;
                var media = document.styleSheets[i].media;
                mediaType = typeof media;
                // IE
                if (mediaType == "string") {
                    if (media == "" || media.indexOf("screen") !=  - 1) {
                        styleSheet = document.styleSheets[i];
                    }
                }
                else if (mediaType == "object") {
                    if (media.mediaText == "" || media.mediaText.indexOf("screen") !=  - 1) {
                        styleSheet = document.styleSheets[i];
                    }
                }
                // stylesheet found, so break out of loop
                if (typeof styleSheet != "undefined")break;
            }
        }
        // if no style sheet is found
        if (typeof styleSheet == "undefined") {
            // create a new style sheet
            var styleSheetElement = document.createElement("style");
            styleSheetElement.type = "text/css";
            // add to <head>
            document.getElementsByTagName("head")[0].appendChild(styleSheetElement);
            // select it
            for (var i = 0; i < document.styleSheets.length; i++) {
                if (document.styleSheets[i].disabled)continue;
                styleSheet = document.styleSheets[i];
            }
            // get media type
            var media = styleSheet.media;
            mediaType = typeof media;
        }
        // IE
        if (mediaType == "string") {
            for (var i = 0; i < styleSheet.rules.length; i++) {
                // if there is an existing rule set up, replace it
                if (styleSheet.rules[i].selectorText.toLowerCase() == selector.toLowerCase()) {
                    styleSheet.rules[i].style.cssText = style;
                    return;
                }
            }
            // or add a new rule
            styleSheet.addRule(selector, style);
        }
        else if (mediaType == "object") {
            for (i = 0; i < styleSheet.cssRules.length; i++) {
                // if there is an existing rule set up, replace it
                if (styleSheet.cssRules[i].selectorText.toLowerCase() == selector.toLowerCase()) {
                    styleSheet.cssRules[i].style.cssText = style;
                    return;
                }
            }
            // or insert new rule
            styleSheet.insertRule(selector + "{" + style + "}", styleSheet.cssRules.length);
        }
    }
}