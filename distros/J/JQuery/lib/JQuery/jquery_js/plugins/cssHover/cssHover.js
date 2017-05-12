/*
 * cssHover - jQuery plugin for accessible, unobtrusive cssHover <http://gilles.jquery.com/cssHover/>
 *
 * Copyright (c) 2006 Gilles van den Hoven (webunity.nl)
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * v0.1
 */

/**
 * Helper functions
 *
 * Because we put the functions in here, this makes the code more readable and prevents them to be
 * bound to each element, and this also preserves some memory usage (i think)
 */
jQuery.cssHover = new function() {
	this.objqCurrent = null;
	this.blnInitialized = false;

	/**
	 * Performs an callback(if assigned) with the jQuery version of this button object
	 */
	this.doCallback = function(fncToCall, objElem) {
		if (fncToCall && (fncToCall.constructor == Function))
			fncToCall(jQuery(objElem));
	};

	//----------------------------------------------------------------------------------------------------

	/**
	 * Creates a transparent image using jQuery, which can not be dragged. If we don't have the "ondrag"
	 * and the mousedown, the className get screwed up because the elements mouseup doesn't get called.
	 */
	this.getNixel = function() {
		return jQuery('<img src="./img/pixel.gif" ondrag="return false;" alt="" title="" />')
			/**
			 * Do not allow this label to be dragged, or the classNames get screwed up.
			 */
			.mousedown(function() { return false; });
	};

	//----------------------------------------------------------------------------------------------------

	/**
	 * Returns the correct jQuery object to work with.
	 * This is needed because of the IMG replacement, to avoid cirular references
	 */
	this.getButtonObject = function(domElem, blnJQuery) {
		blnJQuery = blnJQuery || false;
		objTemp = (domElem.chDomElem != null) ? domElem.chDomElem : domElem;
		return (blnJQuery == true) ? jQuery(objTemp) : objTemp;
	};

	//----------------------------------------------------------------------------------------------------

	/**
	 * Removes the currently active object
	 */
	this.delCurrent = function() {
		// Remove old object
		if (jQuery.cssHover.objqCurrent) {
			jQuery.cssHover.objqCurrent.trigger('mouseup');
		}
		jQuery.cssHover.objqCurrent = null;
	};

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets a new active object
	 */
	this.setCurrent = function(objqElem) {
		// Remove old object
	 	if (jQuery.cssHover.objqCurrent && (jQuery.cssHover.objqCurrent[0].id != objqElem[0].id)) {
			jQuery.cssHover.delCurrent();
		}

		// Set new object
		jQuery.cssHover.objqCurrent = objqElem;
	};

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets the correct class for this element.
	 * @param	object		domElement to change
	 * @param	string		The class to test
	 * @param	boolean		New setting
	 */
	this.setClass = function(objButton, strClass, blnValue, blnIgnoreDisabled) {
		// Do we need to ignore the disabled flag (only set by initializing the component)
		blnIgnoreDisabled = blnIgnoreDisabled || false;

		// Generate the classname
		strTempClass = 'ch_' + objButton.chClass;

		// Do we need to add the classname?
		strTempClass+= (strClass != '') ? '_' + strClass : '';

		// Is this element disabled?
		if (!blnIgnoreDisabled)
			strTempClass+= (!objButton.chBlnEnabled) ? '_disabled' : '';

		// Find the label class
		if (objButton.chObjqLabel)
			strLabelClass = strTempClass.replace(objButton.chClass, 'label');

		// Get handle to jQuery object
		objqTemp = jQuery(objButton);

		// Get current value
		blnCurrent = objqTemp.is('.' + strTempClass);

		// Set new value
		if (blnValue && (!blnCurrent)) {
			objqTemp.addClass(strTempClass);

			// If we have a label, update it
			if (objButton.chObjqLabel) {
				objButton.chObjqLabel.addClass(strLabelClass);
			}
		} else if ((!blnValue) && blnCurrent) {
			objqTemp.removeClass(strTempClass);

			// If we have a label, update it
			if (objButton.chObjqLabel)
				objButton.chObjqLabel.removeClass(strLabelClass);
		}

		// Free object
		objqTemp = null;
	};

	//----------------------------------------------------------------------------------------------------

	/**
	 * Helper function to set the correct class, based on the mouse state
	 */
	this.checkClass = function(objButton) {
		blnMouseOver = jQuery.cssHover.objqCurrent ? (jQuery.cssHover.objqCurrent[0].id == objButton.id) : false;
		objButton.chSetClass('over', (!objButton.chBlnState && blnMouseOver));
		objButton.chSetClass('active', (objButton.chBlnState && !blnMouseOver));
		objButton.chSetClass('active_over', (objButton.chBlnState && blnMouseOver));
	};

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets the state of the cssHover.
	 * @param	object		DOM element to change
	 * @param	boolean		New setting
	 * @param	boolean		Trigger the callback?
	 */
	this.setState = function(objButton, blnValue, blnSkipCallback) {
		// Does the setting change for this element?
		if (blnValue == objButton.chBlnState)
			return;

		if (!objButton.chArrOptions.isToggle)
			return;

		// Default trigger the callback
		blnSkipCallback = (blnSkipCallback === true) ? true : false;

		// Update new value
		objButton.chBlnState = blnValue;

		// Get the object of this button
		objqButton = jQuery.cssHover.getButtonObject(objButton, true);

		// Set setting of corresponding form element (so it gets submitted correctly)
		if ((objButton.chClass == 'checkbox') || (objButton.chClass == 'radio')) {
			objqButton[0].checked = (!objButton.chBlnState) ? '' : 'checked';
		}

		// Update the values of the radio group, but only if we set THIS element to active.
		if ((objButton.chClass == 'radio') && blnValue) {
			// Find all radio elements belonging to thesame group, but not this item
			jQuery('input[@type=radio][@name=' + objqButton[0].name + ']').not('#' + objqButton[0].id).each(function() {
				// Make sure these elements aren't checked, but don't use the chSetState function, this would cause an infinite loop.
				this.checked = '';

				// Make sure the first 2 letters of this ID start with "ch", if so this element probably got replaced
				strID = this.id;
				if (strID.substring(0, 2) == 'ch') {
					// Get a handle to the corresponding replaced cssHover element (if any).
					objDOM = jQuery('#' + strID.substring(2))[0];

					// Double check to see if this element was replaced
					if (objDOM && (typeof objDOM.chClass  == 'string')) {
						// Set their state to false
						objDOM.chBlnState = false;

						// Update CSS to reflect the new setting.
						objDOM.chSetClass('active', this.chBlnState);
					}

					// Free DOM object
					objDOM = null;
				}
				strID = null;
			});
		}

		// Clear button object
		objqButton = null;

		// Set the correct class, depending if the mouse is currently over this item.
		jQuery.cssHover.checkClass(objButton);

		// Callback function?
		if (!blnSkipCallback) {
			jQuery.cssHover.doCallback(objButton.chArrOptions.onChange, objButton);
		}
	};

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets the enabled flag of the cssHover.
	 * @param	object		domElement to change
	 * @param	boolean		New setting
	 */
	this.setEnabled = function(objButton, blnValue) {
		// Does the setting change for this element?
		if (blnValue == objButton.chBlnEnabled)
			return;

		// Update new value
		objButton.chBlnEnabled = blnValue;

		// Set setting of corresponding form element (so it doesn't get submitted)
		jQuery.cssHover.getButtonObject(objButton, false).disabled = (!objButton.chBlnEnabled) ? '' : 'disabled';

		// Set the correct class, depending if the mouse is currently over this item.
		jQuery.cssHover.checkClass(objButton);
	};

	//----------------------------------------------------------------------------------------------------

	/**
	 * Builds the cssHover
	 *
	 * If we are dealing with a RADIO or a CHECKBOX, then we change the DOM element with an IMG. This is
	 * because we can't change the layout of those 2 elements just by classes (because of the owner drawn
	 * layout). This requires extra code, but makes the plugin a lot more usable.
	 *
	 * @param	object		domElement to change
	 * @param	array		Hash with the options
	 */
	this.build = function(domElem, cfgOptions) {
		// Add code to detect mousedown+drag on elements. If we don't add this code, an element could remain
		// in the down state if the mouse was dragged after the mouse was pressed down.
		if (!jQuery.cssHover.blnInitialized) {
			// Set initialized flag
			jQuery.cssHover.blnInitialized = true;

			// Add code (Maybe this could be optimized!?)
			//$('body').mouseup(function() {
					//jQuery.cssHover.delCurrent();
			//});
		}

		// Make sure we don't build twice
		if (typeof domElem.chClass  == 'string') {
			return;
		}

		//----------------------------------------------------------------------------------------------------
		// Gather classname to see if we have to replace the element with images. In case of an input element,
		// we use the "type" attribute. This means, that <input type="button" ..> and <button .. /> have
		// thesame CSS class (button)
		//----------------------------------------------------------------------------------------------------
		strClass = ((domElem.nodeName == 'INPUT') ? domElem.type : domElem.nodeName).toLowerCase();

		// Replace element if needed
		if (strClass == 'checkbox' || strClass == 'radio') {
			// Save handle to old dom element
			objqTemp = jQuery(domElem);

			// Prepend the dom element with an (transparent pixel) image and get a handle to the jQuery object we just created
			objqButton = (jQuery.cssHover.getNixel()).insertBefore(objqTemp);

			// Save handle to old DOM  element
			objqButton[0].chDomElem = domElem;

			// Set the ID of the newly created image to the ID of the dom element
			objqButton[0].id = objqTemp[0].id;

			// Set the ID of the old DOM element to a new ID (prefix: ch) and hide it (we don't need it anymore)
			objqTemp[0].id = 'ch' + objqButton[0].id;

			// Unset the old DOM element
			objqTemp = null;
		} else {
			// Save jQuery object
			objqButton = jQuery(domElem);

			// Set the DOM element to null, so the code knows this element wasn't replaced with an image.
			objqButton[0].chDomElem = null;
		}

		// Define default options and override them with the passed configuration, if available
		objqButton[0].chArrOptions = jQuery.extend({
				hasMouseOver:	false,
				hasMouseDown:	true,
				intInitState:	-1,
				isToggle:		true,
				onChange:		null
			}, cfgOptions || {});

		// Determine the name of the CSS class.
		objqButton[0].chClass = strClass;

		// Set the initial state of the element, default to false
		objqButton[0].chBlnState = (cfgOptions.intInitState == 1) ? true : false;

		// Get a handle to the DOM object
		objqTemp = jQuery.cssHover.getButtonObject(objqButton[0], true);

		// Auto discovery of the value only valid for checkbox & radio button
		if (cfgOptions.intInitState == -1 && (objqButton[0].chClass == 'checkbox' || objqButton[0].chClass == 'radio')) {
			objqButton[0].chBlnState = objqTemp.is(':checked');
		}

		// Set if the cssHover is enabled. Only valid for buttons, checkbox and radio (since those are the only ones we support) and the element must be enabled.
		objqButton[0].chBlnEnabled = objqTemp.is(':enabled');

		/// Functions to set the state of this button. Call them from the DOM.
		objqButton[0].chSetState = function(blnValue, blnForce, blnSkipCallback) {
			blnForce = (blnForce === true) ? true : false;
			blnSkipCallback = (blnForce === true) ? true : false;

			// If this element is disabled, do nothing
			if (!blnForce && !this.chBlnEnabled)
				return;

			// Else, toggle the state
			jQuery.cssHover.setState(this, blnValue, blnSkipCallback);
		};
		objqButton[0].chGetState = function() {
			return this.chBlnState;
		};

		// Functions to set the enabled flag of this button. Call them from the DOM.
		objqButton[0].chSetEnabled = function(blnValue) {
			jQuery.cssHover.setEnabled(this, blnValue);
		};
		objqButton[0].chgetEnabled = function() {
			return this.chBlnEnabled;
		};

		// Private functions for styling this element. You COULD use this from the DOM, but this isn't encouraged.
		objqButton[0].chSetClass = function(strClass, blnValue, blnIgnoreDisabled) {
			jQuery.cssHover.setClass(this, strClass, blnValue, blnIgnoreDisabled || false);
		};

		// Locate the label(s) for this element and save them for later.
		// his is because they also reflect the state of the element.
		objqButton[0].chObjqLabel = null;
		if (objqButton[0].id) {
			objqLabel = jQuery('label[@for=' + objqButton[0].id + ']');
			if (objqLabel.length) {
				objqButton[0].chObjqLabel = objqLabel;

				// Save the "for" attribute so we can use this in the event handlers
				objqButton[0].chObjqLabel[0].chStrFor = objqButton[0].id;
			}
			objqLabel = null;
		}

		// Assign click handler to the newly created element
		if (cfgOptions.isToggle) {
			objqButton.click(function() {
				this.chSetState((this.chClass == 'radio') ? true : (!this.chBlnState));
			});
		}

		// Assign the hover states for the (newly created?) element
		if (objqButton[0].chArrOptions.hasMouseOver) {
			objqButton
				.mouseover(function() {
					// If this element is disabled, do nothing
					if (!this.chBlnEnabled)
						return;

					// Else, add the correct class
					this.chSetClass('over', !this.chBlnState);
					this.chSetClass('active_over', this.chBlnState);
				}).
				mouseout(function() {
					// To be sure, remove both the "normal" over and the "active" over class.
					// The reason for this is that it is theoretically possible to set the "active" state (by code)
					// when the element is hovered over it.
					this.chSetClass('over', false);
					this.chSetClass('active_over', false);

					// If this element is active, set that state
					this.chSetClass('active', this.chBlnState);
				});
		}

		// Assign the mousedown and mouseup states for the (newly created?) element
		if (objqButton[0].chArrOptions.hasMouseDown) {
			objqButton
				.mousedown(function() {
					// If this element is disabled, do nothing
					if (!this.chBlnEnabled)
						return;

					// Else, add the correct class
					this.chSetClass('down', !this.chBlnState);
					this.chSetClass('active_down', this.chBlnState);

					// Save this object
					jQuery.cssHover.setCurrent(jQuery(this));
				})
				.mouseup(function() {
					// Remove the classes
					this.chSetClass('down', false);
					this.chSetClass('active_down', false);
				})
				.mouseout(function() {
					jQuery.cssHover.delCurrent();
				});
		}

		// For a checkbox and a radio button we need to add some extra event handlers, depending on wether there is a label present.
		// This is because we HIDE those elements, thus we need some handlers to catch the label presses and stuff
		if ((strClass == 'checkbox') || (strClass == 'radio')) {
			// Get a handle to the checkbox/radio button
			objqTemp = jQuery('#ch' + objqButton[0].id);

			// If we have a label, hide the replaced checkbox/radio button
			if (objqButton[0].chObjqLabel != null) {
				// Add handlers to toggle the element, these elements are delegated to the DOM element we are the label for.
				if (cfgOptions.isToggle) {
					objqButton[0].chObjqLabel.
						click(function() {
							jQuery('#' + this.chStrFor + ':eq(0)').trigger('click');
						});
				}

				// Add handlers to get the mouseover states, these elements are delegated to the DOM element we are the label for.
				if (objqButton[0].chArrOptions.hasMouseOver) {
					objqButton[0].chObjqLabel
						.mouseover(function() {
							jQuery('#' + this.chStrFor + ':eq(0)').trigger('mouseover');
						})
						.mouseout(function() {
							jQuery('#' + this.chStrFor + ':eq(0)').trigger('mouseout');
						});
				}

				// Add handlers to get the mousedown states, these elements are delegated to the DOM element we are the label for.
				if (objqButton[0].chArrOptions.hasMouseDown) {
					objqButton[0].chObjqLabel
						.mousedown(function() {
							jQuery('#' + this.chStrFor + ':eq(0)').trigger('mousedown');
						})
						.mouseup(function() {
							jQuery('#' + this.chStrFor + ':eq(0)').trigger('mouseup');
						});
				}
			}

			// Assign custom handler
			objqTemp[0].chSetState = function(blnState, blnForce, blnSkipCallback) {
				blnForce = (blnForce === true) ? true : false;
				blnSkipCallback = (blnSkipCallback === true) ? true : false;
				jQuery('#' + this.id.substring(2))[0].chSetState(blnState, blnForce, blnSkipCallback);
			}

			// Assign event handlers
			objqTemp
				/*
				 * Move the element off screen, to support the "focus" classname.
				 */
				.css({
					position: 'absolute',
					left: '-1000px'
				})
				/*
				 * When the user presses the spacebar on the focused element, the natural way is to toggle the element.
				 * Since the element is invisible (off-screen) for the user, we need to toggle the new element we
				 * created in place. Toggle the state if we are a checkbox, else we are a radio button and we need to
				 * set the value to TRUE. If we are a radio button, the function we are calling makes sure all other
				 * elements in the (radio)group are set to false. The spacebar toggles the "click" event.
				 */
				.click(function() {
					this.chSetState(jQuery(this).is(':checked'));
				})
				.focus(function() {
					// Get a handle to the new DOM elemen
					objElem = jQuery('#' + this.id.substring(2))[0];

					// If this element is disabled, do nothing
					if (!objElem.chBlnEnabled)
						return;

					// Else, add the focus class
					objElem.chSetClass('focus', !objElem.chBlnState);
					objElem.chSetClass('active_focus', objElem.chBlnState);
				})
				.blur(function() {
					// Get a handle to the new DOM elemen
					objElem = jQuery('#' + this.id.substring(2))[0];

					// Remove the "focus" class
					objElem.chSetClass('focus', false);
					objElem.chSetClass('active_focus', false);
				});
		} else {
			// Hover states
			objqButton
				.focus(function() {
					// If this element is disabled, do nothing
					if (!this.chBlnEnabled)
						return;

					// Else, add the focus class
					this.chSetClass('focus', !this.chBlnState);
					this.chSetClass('active_focus', this.chBlnState);
				})
				.blur(function() {
					// Remove the "focus" class
					this.chSetClass('focus', false);
					this.chSetClass('active_focus', false);
				});
		}

		// To allow customizing of these cssHovers, we now:
		// - get the initial classNames of the element
		strOldButtonClass = objqButton[0].className;
		objqButton[0].className = '';

		// And of the label, if needed
		if (objqButton[0].chObjqLabel) {
			strOldLabelClass = objqButton[0].chObjqLabel[0].className;
			objqButton[0].chObjqLabel[0].className = '';
		}

		// - Add the cssHover class to reflect the right object type. This also makes sure the cssHover class comes first since
		//   we've reset the classNames in the above code. This code also sets the classname on the label
		objqButton[0].chSetClass('', true, true);

		// Make sure any allready disabled element also received the disabled state
		if (!objqButton[0].chBlnEnabled) {
			objqButton[0].chSetClass('', true);
		}

		// - Add the old style after it, so we can override the cssHover class
		objqButton.addClass(strOldButtonClass);
		if (objqButton[0].chObjqLabel) {
			objqButton[0].chObjqLabel.addClass(strOldLabelClass);
		}

		// Clean up
		strOldButtonClass = null;
		strOldLabelClass = null;

		// Make sure the element reflects the current state
		objqButton[0].chSetClass('active', objqButton[0].chBlnState);
	};
};

/**
 * Main function, used to build the buttons on all matched ellements
* @param	array		Hash with the options
 */
jQuery.fn.cssHover = function(cfgOptions) {
	cfgOptions = cfgOptions || {};
	return this.each(function() { jQuery.cssHover.build(this, cfgOptions); });
};