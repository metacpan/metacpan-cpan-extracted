/*
 * searchField - jQuery plugin to display and remove
 * a default value in a searchvalue on blur/focus
 *
 * Copyright (c) 2007 Jörn Zaefferer, Paul McLanahan
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 */

/**
 * Clear the help text in a search field (either in the value or title attribute)
 * when focused, and restore it on blur if nothing was entered. If the value is
 * blank but there is a title attribute, the title will be moved to the initial value.
 *
 * @example $('#quicksearch').searchField();
 * @before <input id="quicksearch" title="Enter search here" name="quicksearch" />
 * @result <input id="quicksearch" value="Enter search here" name="quicksearch" />
 *
 * @name searchField
 * @type jQuery
 * @cat Plugins/SearchField
 */
jQuery.fn.searchField = function(){
	return this.each(function(){
		var $this = jQuery(this);
		// setup initial value from title if no initial value
		if(this.title && this.title.length && !this.value.length){
			$this.val(this.title);
			$this.removeAttr('title');
		}
		// attach listeners if there is a value
		if(this.value.length){
			this.defaultValue = this.value;
			$this.focus(function(){
				if(this.value==this.defaultValue) this.value='';
			})
			.blur(function(){
				if(!this.value.length)this.value=this.defaultValue;
			});
		}
	});
};