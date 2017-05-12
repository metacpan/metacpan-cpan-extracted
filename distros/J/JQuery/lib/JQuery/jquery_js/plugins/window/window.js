/*
 * window - jQuery plugin to easily create dialogs <http://gilles.jquery.com/window/>
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
 * Window constructor
 * Couldn't name it "window", so instead i named it jqWindow
 */
function jqWindow() {
		this.blnInitialized = false;
		this.objqHelper = null;				// Helper object for various effects
		this.intZIndex = 873;
		this.objqActive = null;
		this.arrWindows = new Array();
}

/**
 * Window functions
 */
jqWindow.prototype = {
	/*
	 * Returns array with page width, height and window width, height
	 * This code was taken from: www.quirksmode.org
	 * Edit for Firefox by pHaez
	 * -----
	 * Edit by Gilles vd Hoven (also returning screen width, screen height and scroll offsets)
	 */
	getClientInfo: function() {
		// Get scroll offsets
		var intScrollLeft, intScrollTop;
		if (document.documentElement && document.documentElement.scrollTop) {
			intScrollLeft = document.documentElement.scrollLeft;
			intScrollTop = document.documentElement.scrollTop;
		} else {
			if (document.body) {
				intScrollLeft = document.body.scrollLeft;
				intScrollTop = document.body.scrollTop;
			} else {
				if (window.pageYOffset) {
					intScrollLeft = window.pageXOffset;
					intScrollTop = window.pageYOffset;
				}
			}
		}

		// Get document size
		var intDocumentWidth, intDocumentHeight;
		if (document.documentElement && document.documentElement.clientHeight) { // Explorer 6 Strict Mode
			intDocumentWidth = document.documentElement.clientWidth;
			intDocumentHeight = document.documentElement.clientHeight;
		} else {
				if (document.body) { // other Explorers
					intDocumentWidth = document.body.clientWidth;
					intDocumentHeight = document.body.clientHeight;
				} else {
						if (self.innerHeight) {	// all except Explorer
							intDocumentWidth = self.innerWidth;
							intDocumentHeight = self.innerHeight;
						}
				}
		}

		// Get screen size
		var intScreenWidth, intScreenHeight;
		if (self.screen) {
			intScreenWidth = self.screen.width;
			intScreenHeight = self.screen.height;
		}

		// for small pages with total width less then width of the viewport
		var intPageWidth, intPageHeight;
		intPageWidth = (intScrollLeft < intDocumentWidth) ? intDocumentWidth : intScrollLeft;
		intPageHeight = (intScrollTop < intDocumentHeight) ? intDocumentHeight : intScrollTop;

		return {
				pageWidth: intPageWidth,
				pageHeight: intPageHeight,
				documentWidth: intDocumentWidth,
				documentHeight: intDocumentHeight,
				screenWidth: intScreenWidth,
				screenHeight: intScreenHeight,
				scrollLeft: intScrollLeft,
				scrollTop: intScrollTop
			};
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Removes the element from the window list by its key
	 * @return	boolean
	 */
	updateWindows: function() {
		for (var intCurrent=0; intCurrent<jqWindow.arrWindows.length; intCurrent++) {
			// Get object
			objWindow = jqWindow.arrWindows[intCurrent][0];
			if (!objWindow)
				continue;

			// Update positions
			if (
					((objWindow.jw.intWindowState == -1) || (objWindow.jw.intWindowState == 1)) ||		// Update when maximized/minimized
					((objWindow.jw.hshOptions.intPosition != 0) && (!objWindow.jw.blnIsMoved))				// And update when not yet moved and centered
					) {
				hshNew = jqWindow.calcLeftTop(objWindow, objWindow.jw.hshOptions.hshDimensions);

				jqWindow.setOffset(objWindow, hshNew);
			}
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Gets the window from the array by name
	 * @return	boolean
	 */
	getByName: function(strName) {
		arrTemp = new Array();
		for (var intCurrent=0; intCurrent<jqWindow.arrWindows.length; intCurrent++) {
			objWindow = jqWindow.arrWindows[intCurrent][0];
			if (objWindow && objWindow.jw.hshOptions.strName == strName) {
				return objWindow;
			}
		}
		return false;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Removes the element from the window list by its key
	 * @return	boolean
	 */
	removeByName: function(strName) {
		arrTemp = new Array();
		for (var intCurrent=0; intCurrent<jqWindow.arrWindows.length; intCurrent++) {
			objWindow = jqWindow.arrWindows[intCurrent][0];
			if (objWindow && objWindow.jw.hshOptions.strName != strName) {
				arrTemp[arrTemp.length] = objWindow;
			}
		}
		jqWindow.arrWindows = arrTemp;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Checks to see if the passed value is a hash
	 * @param	array		Hash to check
	 * @return	boolean
	 */
	isHash: function(hshValue) {
		return (hshValue && (typeof hshValue == 'object') && (hshValue.constructor == Object));
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Performs an callback(if assigned) with the jQuery version of this button object
	 */
	doCallback: function(fncToCall, objWindow) {
		if (fncToCall && (fncToCall.constructor == Function))
			fncToCall(jQuery(objWindow));
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Calls the LOAD callback function. Since this function is executed with the content object, we need
	 * to find the DIALOG.
	 * @param	jQuery CONTENT object
	 */
	cbLoad: function(objqContent) {
		// Get the DOM window object
		objWindow = jQuery(objqContent)		// Content TD
							.parent()		// DIV/IFRAME > TD
							.parent()		// TD > TR
							.parent()		// TR > TBODY
							.parent()		// TBODY > TABLE
							.parent()[0];	// TABLE > DIV > get DOM object

		// Perform the callback
		jqWindow.doCallback(objWindow.jw.hshOptions.onLoad, objWindow);
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Will be executed whenever a focus event is triggered on the document.
	 * @param	EVENT
	 * @return	boolean
	 */
	focusHandler: function(oEvent) {
		// Only bother if we don't have a window object
		if (jqWindow.objqActive) {
			// Only bother if the current window object is modal
			objWindow = jqWindow.objqActive[0];
			if (objWindow.jw.hshOptions.blnIsModal) {
				// Only continue if we have a DOM element
				if (objElem = (oEvent.srcElement || oEvent.target)) {
					return (jQuery(jqWindow.objqActive).children(objElem).length > 0);
				}
			}
		}

		// In all other cases, the focus is allowed
		return true;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Performs the correct action based on a single or double click
	 * @param	event
	 */
	cbTitlebarHandler: function(oEvent) {
		// Get the DOM window object
		objWindow = jQuery(this)		// Titlebar table
									.parent()[0];	// Titlebar > Dialog

		// Make the dialog active
		jqWindow.setActive(objWindow);

		// If the window is minimized, or maximized, restore it.
		if ((objWindow.jw.intWindowState == -1) || (objWindow.jw.intWindowState == 1)) {
			jqWindow.doRestore(objWindow);
		} else {
			// If we have a maximize button; maximize, or restore the window, depending on the state of the button.
			if (objWindow.jw.objqBtnMaximize) {
				objWindow.jw.objqBtnMaximize[0].chSetState(true);
			}
		}

		// Prevent this event from bubbling
		return false;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Removes the element from the window list by its key
	 * @return	boolean
	 */
	updatePadding: function(objWindow) {
		if (objWindow.jw.objqIFrame != null) {
			hshOptions = jQuery.iUtil.getSize(objWindow.jw.objqIFrame[0]);
		} else if (objWindow.jw.objqContent != null) {
			hshOptions = jQuery.iUtil.getSize(objWindow.jw.objqContent[0]);
		}
		objWindow.jw.intPadding = (hshOptions.hb > hshOptions.h) ? (hshOptions.hb - hshOptions.h) : 0;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Calculates the position of the window, taking the "position" property into account.
	 * @param	DOM window object
	 * @param	hash
	 * @return	integer
	 */
	calcLeftTop: function(objWindow, hshDimensions) {
		// Initialize the new hash (with integers)
		hshTemp = {
			left: parseInt(hshDimensions.left) || 0,
			top: parseInt(hshDimensions.top) || 0,
			width: parseInt(hshDimensions.width) || 0,
			height: parseInt(hshDimensions.height) || 0
		};

		// Don't bother if the window is moved, or if the position == 0
		if (objWindow.jw.blnIsMoved || (objWindow.jw.hshOptions.intPosition == 0)) {
			return hshTemp;
		}

		// Calculate right offset
		hshClientInfo = jqWindow.getClientInfo();
		if (objWindow.jw.intWindowState == 0) {
			hshTemp.left = (hshClientInfo.documentWidth - hshTemp.width) / 2;
			hshTemp.top = (hshClientInfo.documentHeight - hshTemp.height) / 2;
		}

		// Get correct height
		if (objWindow.jw.intWindowState == -1) {
			hshTemp.height = parseInt(objElem.jw.objqTitleWrp.height()) || 0;
			hshTemp.top = (hshClientInfo.documentHeight - hshTemp.height);
		}

		// Add scroll offset
		hshTemp.top+= (objWindow.jw.hshOptions.intPosition == 1) ? hshClientInfo.scrollTop : 0;

		// Return new hash
		return hshTemp;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Increases the ZIndex and returns the new value
	 * @return	integer
	 */
	newZIndex: function() {
		jqWindow.intZIndex+= 128;
		return jqWindow.intZIndex;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * CHecks the ZIndex of this window and updates the objects accordingly
	 * @return	integer
	 */
	checkZIndex: function(objWindow) {
		// Update window
		jQuery(objWindow).css('zIndex', objWindow.jw.intZIndex);

		// Update overlay
		if (objWindow.jw.blnIsModal) {
			objWindow.jw.objqOverlay.css('zIndex', (objWindow.jw.intZIndex - 1));
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Will be executed whenever a focus event is triggered on the document.
	 * @param	EVENT
	 * @return	boolean
	 */
	saveState: function(objWindow) {
		// Save the current window sate
		objWindow.jw.hshViewState = objWindow.jw.hshOptions.hshDimensions;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Changes the size of the window using a transfer effect if that was enabled
	 * @param	EVENT
	 * @return	boolean
	 */
	transferDimensions: function(objWindow, hshDimensions) {
		if (objWindow.jw.hshOptions.blnTransfer) {
			// Set the dimensions of the transfer helper to match the viewport
			jqWindow.objqHelper.css({
					left: hshDimensions.left + 'px',
					top: hshDimensions.top + 'px',
					width: hshDimensions.width + 'px',
					height: hshDimensions.height + 'px'
				}).show();

			// Minimize this window to the size of the transfer helper
		 	jQuery(objWindow).TransferTo({
					to: jqWindow.objqHelper[0],
					className: 'jwTransferring',
					duration: 250,
					complete: function() {
						// Hide helper
						jqWindow.objqHelper.hide();

						// Set new dimensions
						jqWindow.setDimensions(objWindow, hshDimensions, false, true);
					}
		 		});
		} else {
			// Set new dimensions
			jqWindow.setDimensions(objWindow, hshDimensions, false, true);
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Actually minimize the window
	 * @param	jQuery element
	 */
	doMinimize: function(objWindow) {
		// Only save the new window state if the window wasn't maximized and if this function wasn't called when the window resized
		if (objWindow.jw.intWindowState == 0) {
			jqWindow.saveState(objWindow);
		}

		// If we are maximized
		if (objWindow.jw.intWindowState == 1) {
			jqWindow.doRestore(objWindow, false);
		} else {
			// Make the dialog active
			jqWindow.setActive(objWindow);
		}

		// Set new windowstate
		objWindow.jw.intWindowState = -1;

		// Get page sizes
		hshClientInfo = jqWindow.getClientInfo();

		// Calculate new state
		intWidth = parseInt(objWindow.jw.hshOptions.hshDimensions.width) || 0;
		intHeight = parseInt(objWindow.jw.objqTitleWrp.height()) || 0;

		// Initialize default options
		hshDimensions = {
			left: 0,
			top: (hshClientInfo.scrollTop + hshClientInfo.documentHeight - intHeight),
			width: objWindow.jw.hshOptions.intMimimizedWidth || intWidth,
			height: intHeight
		};

		// When minimized, don't allow an active resizable
		jqWindow.setIsResizable(objWindow, false, false);

		// And make sure the window gets this state
		jqWindow.transferDimensions(objWindow, hshDimensions);
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Changes the size of the window using a transfer effect if that was enabled
	 * @param	EVENT
	 * @return	boolean
	 */
	doRestore: function(objWindow, blnRestoreDimensions) {
		// Don't call restore before position is set.
		if (!objWindow.jw.hshViewState)
			return;

		// Update buttons
		if (objWindow.jw.objqBtnMinimize && (objWindow.jw.intWindowState == -1)) {
			objWindow.jw.objqBtnMinimize[0].chSetState(false, true, true);
		}

		if (objWindow.jw.objqBtnMaximize && (objWindow.jw.intWindowState == 1)) {
			objWindow.jw.objqBtnMaximize[0].chSetState(false, true, true);
		}

		// Restore window state
		objWindow.jw.intWindowState = 0;
		blnRestoreDimensions = (blnRestoreDimensions === false) ? false : true;

		// Transfer window back to original position
		if (blnRestoreDimensions) {
			// Restore the viewstate, but make sure the window has the right LEFT and TOP position
			objWindow.jw.hshOptions.hshDimensions = jqWindow.calcLeftTop(objWindow, objWindow.jw.hshViewState);

			// Clear position array
			objWindow.jw.hshViewState = null;

			// Tranfser effect
			if (objWindow.jw.hshOptions.blnTransfer) {
				// Set the dimensions of the transfer helper to match the object
				jqWindow.objqHelper.css({
						left: objWindow.jw.hshOptions.hshDimensions.left + 'px',
						top: objWindow.jw.hshOptions.hshDimensions.top + 'px',
						width: objWindow.jw.hshOptions.hshDimensions.width + 'px',
						height: objWindow.jw.hshOptions.hshDimensions.height + 'px'
					});

				// Restore this window to the original size before it was maximized.
			 	jQuery(objWindow).TransferTo({
						to: jqWindow.objqHelper[0],
						className: 'jwTransferring',
						duration: 250,
						complete: function() {
							jqWindow.setDimensions(objWindow, objWindow.jw.hshOptions.hshDimensions);
						}
			 		});
		 	} else {
				jqWindow.setDimensions(objWindow, objWindow.jw.hshOptions.hshDimensions);
		 	}
		}

		// Restore draggable and resizable
		jqWindow.setIsDraggable(objWindow, objWindow.jw.hshOptions.blnIsDraggable, false);
		jqWindow.setIsResizable(objWindow, objWindow.jw.hshOptions.blnIsResizable, false);

		// Make the dialog active
		jqWindow.setActive(objWindow);
	},

	/**
	 * Actually maximize the window
	 * @param	jQuery element
	 */
	doMaximize: function(objWindow) {
		// Only save the new window state if the window wasn't maximized and if this function wasn't called when the window resized
		if (objWindow.jw.intWindowState == 0) {
			jqWindow.saveState(objWindow);
		}

		// If we are minimized
		if (objWindow.jw.intWindowState == -1) {
			// Restore buttons
			jqWindow.doRestore(objWindow, false);

			// Make sure we don't save the viewstate
			blnSaveState = false;
		} else {
			// Make the dialog active
			jqWindow.setActive(objWindow);
		}

		// Update padding
		jqWindow.updatePadding(objWindow);

		// Set new windowstate
		objWindow.jw.intWindowState = 1;

		// Get page sizes
		hshClientInfo = jqWindow.getClientInfo();

		// Calculate the new hash
		hshDimensions = {
			left: 0,
			top: hshClientInfo.scrollTop,
			width: hshClientInfo.documentWidth,		// To prevent scrollbars from appearing
			height: hshClientInfo.documentHeight	// To prevent scrollbars from appearing
		};

		// Minus the header and the footer height
		hshDimensions.height-= objWindow.jw.intPadding;

		// Calculate new state
		if (jqWindow.isHash(objWindow.jw.hshOptions.hshMaxSize)) {
			// Initialize default options
			hshDimensions = {
				left: 0,
				top: 0,
				width: objWindow.jw.hshOptions.hshMaxSize.width,
				height: objWindow.jw.hshOptions.hshMaxSize.height
			};

			// Make sure the window has the right LEFT and TOP position
			hshDimensions = jqWindow.calcLeftTop(objWindow, hshDimensions);
		}

		// And make sure the window gets this state
		jqWindow.transferDimensions(objWindow, hshDimensions);

		// When maximized, don't allow an active draggable and resizable
		jqWindow.setIsDraggable(objWindow, false, false);
		jqWindow.setIsResizable(objWindow, false, false);
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets the new theme of this window.
	 * @param	object
	 * @param	string
	 */
	setTheme: function(objWindow, strValue) {
		// Update the window theme
		jQuery(objWindow).removeClass('theme' + objWindow.jw.hshOptions.strTheme).addClass('theme' + strValue);

		// Save new value
		objWindow.jw.hshOptions.strTheme = strValue;

		// Only do this, after the window has been initialized
		if (objWindow.jw.blnInitialized) {
			// Make sure the content part is still the correct size, according to the newly calculated offsets
			jqWindow.setDimensions(objWindow, objWindow.jw.hshOptions.hshDimensions);
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Updates the position of this window
	 * @param DOM element
	 * @param hash
	 */
	setOffset: function(objWindow, hshValues) {
		intHeight = hshValues.height;

		// Set correct height when minimized
		if (objWindow.jw.intWindowState == -1) {
			objWindow.jw.objqContentWrp.hide();
			objWindow.jw.objqStatusWrp.hide();
			intHeight = parseInt(objWindow.jw.objqTitleWrp.height()) || 0;
		} else {
			objWindow.jw.objqContentWrp.show();
			objWindow.jw.objqStatusWrp.show();
		}

		// Update wrapper left and top position
		jQuery(objWindow).css({
				left: hshValues.left + 'px',
				top: hshValues.top + 'px',
				width: hshValues.width + 'px',
				height: intHeight + 'px'
			});

		// Don't update the height of the content part when minimized
		if (objWindow.jw.intWindowState == -1) {
			return;
		}

		//
		// Remove titlebar and statusbar height
		intHeight-= parseInt(objWindow.jw.objqTitleWrp.height()) || 0;
		intHeight-= parseInt(objWindow.jw.objqStatusWrp.height()) || 0;

		//
		// Update content sizes
		if (objWindow.jw.objqIFrame != null) {
			objWindow.jw.objqIFrame.css({
					height: intHeight + 'px'
				});

		} else if (objWindow.jw.objqContent != null) {
			objWindow.jw.objqContent.css({
					height: intHeight + 'px'
				});
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Updates the dimensions of this window
	 * @param DOM element
	 * @param hash
	 * @param boolean		DEFAULTS to false
	 * @param boolean		DEFAULTS to false
	 */
	setDimensions: function(objWindow, hshValues, blnSetMoved, blnForce) {
		// Make sure we have an array, or else reset the passed value
		if (!jqWindow.isHash(hshValues)) {
			return;
		}

		// Set the "moved" flag?
		blnSetMoved = (blnSetMoved === true) ? true : false;
		if (blnSetMoved) {
			objWindow.jw.blnIsMoved = true;
		}

		// Force the size?
		blnForce = (blnForce === true) ? true : false;

		// The positions can't be set if the window is minimized or maximized
		if (!blnForce) {
			if ((objWindow.jw.objqBtnMinimize && (objWindow.jw.intWindowState == -1)) ||
				(objWindow.jw.objqBtnMaximize && (objWindow.jw.intWindowState == 1))) {
				return;
			}
		}

		// Make sure that the new size is not smaller then the minimum size
		// We only do this if the minimim size is not "0" (means NO minimum size)
		if (jqWindow.isHash(objWindow.jw.hshOptions.hshMinSize)) {
			// Check width
			if ((objWindow.jw.hshOptions.hshMinSize.width != 0) &&
				(hshValues.width < objWindow.jw.hshOptions.hshMinSize.width)) {
				hshValues.width = objWindow.jw.hshOptions.hshMinSize.width;
			}

			// Check height
			if ((objWindow.jw.hshOptions.hshMinSize.height != 0) &&
				(hshValues.height < objWindow.jw.hshOptions.hshMinSize.height)) {
				hshValues.height = objWindow.jw.hshOptions.hshMinSize.height;
			}
		}

		// Make sure that the new size is not bigger then the maximum size
		// We only do this if the maximum size is not "0" (means NO maximum size)
		if (jqWindow.isHash(objWindow.jw.hshOptions.hshMaxSize)) {
			// Check width
			if ((objWindow.jw.hshOptions.hshMaxSize.width != 0) &&
				(hshValues.width > objWindow.jw.hshOptions.hshMaxSize.width)) {
				hshValues.width = objWindow.jw.hshOptions.hshMaxSize.width;
			}

			// Check height
			if ((objWindow.jw.hshOptions.hshMaxSize.height != 0) &&
				(hshValues.height > objWindow.jw.hshOptions.hshMaxSize.height)) {
				hshValues.height = objWindow.jw.hshOptions.hshMaxSize.height;
			}
		}

		// Update window positions, but prevent passing by reference
		hshTemp = {
				left: hshValues.left,
				top: hshValues.top,
				width: hshValues.width,
				height: hshValues.height
			};
		jqWindow.setOffset(objWindow, hshTemp);

		// Save new settings
		objWindow.jw.hshOptions.hshDimensions = hshValues;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets if the window uses an IFRAME for the content.
	 * @param	object
	 * @param	boolean
	 */
	setIFrame: function(objWindow, blnValue) {
		if (blnValue) {
			if (!objWindow.jw.objqIFrame) {
				// Remove the IFrame if it exists
				if (objWindow.jw.objqContent) {
					objWindow.jw.objqContent.remove();
					objWindow.jw.objqContent = null;
				}

				// Create new content IFrame
		 		objWindow.jw.objqIFrame = jQuery('<iframe></iframe>').css({
			 										width: '100%',
			 										border: 'none'
		 										});

				// Add this to the content TD
		 		jQuery('TD.jwContentC:eq(0)', objWindow.jw.objqContentWrp)
		 			.empty()
		 			.css({
							fontSize: '1px',
							lineHeight: '1px'
						})
		 			.append(objWindow.jw.objqIFrame);
		 	}
		} else {
			if (!objWindow.jw.objqContent) {
				// Remove the IFrame if it exists
				if (objWindow.jw.objqIFrame) {
					objWindow.jw.objqIFrame.remove();
					objWindow.jw.objqIFrame = null;
				}

				// Create new content DIV
				objWindow.jw.objqContent = jQuery('<div class="jwContent">&nbsp;</div>').css({
													display: 'block',
													overflow: 'auto'
												});

				// Add this to the content TD
		 		jQuery('TD.jwContentC:eq(0)', objWindow.jw.objqContentWrp)
		 			.empty()
		 			.css({
							fontSize: '',
							lineHeight: ''
						})
		 			.append(objWindow.jw.objqContent);
			}
		}

		// Update dimensions
		jqWindow.setDimensions(objWindow, objWindow.jw.hshOptions.hshDimensions);
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets if the window is modal (and thus has an overlay and a restricted focus set)
	 * @param	object
	 * @param	boolean
	 */
	setIsModal: function(objWindow, blnValue) {
		// We can't set the modal state of this window if:
		// - There is an active window
		// - That window isn't thesame as this one
		// - That window is allready modal (the modal window is always on top)
		// If there is an active modal window, and this
		if (jqWindow.objqActive &&
			(blnValue == true) &&
			(jqWindow.objqActive[0].jw.hshOptions.strName != objWindow.jw.hshOptions.strName) &&
			(jqWindow.objqActive[0].jw.hshOptions.blnIsModal == true)
			) {
			blnValue = false;
		}

		// Update the new value
		if (blnValue) {
			if (!objWindow.jw.objqOverlay) {
		 		objWindow.jw.objqOverlay = jQuery(document.createElement('div'))
											.addClass('theme' + objWindow.jw.hshOptions.strTheme)
		 									.addClass('dialogOverlay')
		 									.css({
				 									zIndex: objWindow.jw.intZIndex - 1
				 								});

		 		jQuery(objWindow).before(objWindow.jw.objqOverlay);
		 	}
		} else {
			if (objWindow.jw.objqOverlay) {
				objWindow.jw.objqOverlay.remove();
				objWindow.jw.objqOverlay = null;
			}
		}

		// Save new value
		objWindow.jw.hshOptions.blnIsModal = blnValue;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets if the window has a minimize button
	 * @param	object
	 * @param	boolean
	 */
	setHasMinimize: function(objWindow, blnValue) {
		if (blnValue) {
			if (!objWindow.jw.objqBtnMinimize) {
				// Create the button
		 		objWindow.jw.objqBtnMinimize = jQuery(document.createElement("div"))
		 						.html('&nbsp;')
		 						.addClass('btnMinimize')
		 						.css({
										fontSize: '1px',
										lineHeight: '1px'
									})
		 						.cssHover({
										hasMouseOver:	true,
										hasMouseDown:	true,
										isToggle: true,
		 								intInitState: ((objWindow.jw.intWindowSate == -1) ? 1 : 0),
		 								onChange: jqWindow.cbMinimizeHandler
		 							});

				// Add the button object
		 		objWindow.jw.objqButtonWrp.append(objWindow.jw.objqBtnMinimize);

				// Add the click handler, only if there is no maximize button
				if (!objWindow.jw.objqBtnMaximize) {
					objWindow.jw.objqTitleWrp.dblclick( jqWindow.cbTitlebarHandler );
				}
		 	}
		} else {
			if (objWindow.jw.objqBtnMinimize) {
				// Remove click handler
				if (!objWindow.jw.objqBtnMaximize) {
					objWindow.jw.objqTitleWrp.undblclick( jqWindow.cbTitlebarHandler );
				}

				// Remove the button, only if there is no maximize button
				objWindow.jw.objqBtnMinimize.remove();
				objWindow.jw.objqBtnMinimize = null;
			}
		}

		// Save new value
		objWindow.jw.hshOptions.blnHasMinimize = blnValue;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * This handler gets called when the minimize button has changed states. cssHover fires this callback.
	 * @param	jQuery element
	 */
	cbMinimizeHandler: function(objqButton) {
		// Retreive the window object
		objWindow = objqButton.parent().parent()[0];

		// State is true, MINIMIZE
		if (objWindow.jw.intWindowState != -1) {
			jqWindow.doMinimize(objWindow);
		} else {
			jqWindow.doRestore(objWindow);
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets if the window has a maximize button
	 * @param	object
	 * @param	boolean
	 */
	setHasMaximize: function(objWindow, blnValue) {
		if (blnValue) {
			if (!objWindow.jw.objqBtnMaximize) {
				// Create the button
		 		objWindow.jw.objqBtnMaximize = jQuery(document.createElement("div"))
		 						.html('&nbsp;')
		 						.addClass('btnMaximize')
		 						.css({
										fontSize: '1px',
										lineHeight: '1px'
									})
		 						.cssHover({
										hasMouseOver:	true,
										hasMouseDown:	true,
										isToggle: true,
		 								intInitState: ((objWindow.jw.intWindowSate == 1) ? 1 : 0),
		 								onChange: jqWindow.cbMaximizeHandler
		 							});

		 		// Add the button
		 		objWindow.jw.objqButtonWrp.append(objWindow.jw.objqBtnMaximize);

				// Add the click handler, only if there is no minimize button
				if (!objWindow.jw.objqBtnMinimize) {
					objWindow.jw.objqTitleWrp.dblclick( jqWindow.cbTitlebarHandler );
				}
		 	}
		} else {
			if (objWindow.jw.objqBtnMaximize) {
				// Remove the click handler, only if there is no minimize button
				if (!objWindow.jw.objqBtnMinimize) {
					objWindow.jw.objqTitleWrp.undblclick( jqWindow.cbTitlebarHandler );
				}

				// Remove the button
				objWindow.jw.objqBtnMaximize.remove();
				objWindow.jw.objqBtnMaximize = null;
			}
		}

		// Save new value
		objWindow.jw.hshOptions.blnHasMaximize = blnValue;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * This handler gets called when the maximize button has changed states. cssHover fires this callback.
	 * @param	jQuery element
	 */
	cbMaximizeHandler: function(objqButton) {
		// Retreive the window object
		objWindow = objqButton.parent().parent()[0];

		// State is true, MAXIMIZE
		if (objWindow.jw.intWindowState != 1) {
			jqWindow.doMaximize(objWindow);
		} else {
			// State is false, restore it
			jqWindow.doRestore(objWindow);
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets if the window has a close button
	 * @param	object
	 * @param	boolean
	 */
	setHasClose: function(objWindow, blnValue) {
		if (blnValue) {
			if (!objWindow.jw.objqBtnClose) {
		 		objWindow.jw.objqBtnClose = jQuery(document.createElement("div"))
		 						.html('&nbsp;')
		 						.addClass('btnClose')
		 						.css({
										fontSize: '1px',
										lineHeight: '1px'
									})
		 						.cssHover({
										hasMouseOver:	true,
										hasMouseDown:	true,
										isToggle:		false,
										intInitState:	0
		 							})
		 						.click(jqWindow.cbCloseHandler);
		 		objWindow.jw.objqButtonWrp.append(objWindow.jw.objqBtnClose);
		 	}
		} else {
			if (objWindow.jw.objqBtnClose) {
				objWindow.jw.objqBtnClose.remove();
				objWindow.jw.objqBtnClose = null;
			}
		}

		// Save new value
		objWindow.jw.hshOptions.blnHasClose = blnValue;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * This handler gets called when the close button is clicked. Assigned in this code.
	 * @param	EVENT
	 */
	cbCloseHandler: function(oEvent) {
		// Get the event object
		if (objButton = (oEvent.srcElement || oEvent.target)) {
			// Retreive the window object
			objWindow = jQuery(objButton).parent().parent()[0];

			// Remove the window object
			jqWindow.destroy(objWindow);
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Enables or disables the status bar
	 * @param boolean
	 */
	setHasStatus: function(objWindow, blnValue) {
		// Set correct class
		if (blnValue) {
			// Disable resize grip
			jqWindow.setIsResizable(objWindow, objWindow.jw.hshOptions.blnIsResizable, false);

			// Set status text
			jqWindow.setStatus(objWindow, objWindow.jw.hshOptions.strStatus);

			// Set the correct layout of the statusbar
			objWindow.jw.objqStatusWrp.removeClass('jwNoStatus').addClass('jwStatus');
		} else {
			// Disable resize grip
			jqWindow.setIsResizable(objWindow, objWindow.jw.hshOptions.blnIsResizable, false);

			// Clear status text
			jqWindow.setStatus(objWindow, '');

			// Set the correct layout of the statusbar
			objWindow.jw.objqStatusWrp.removeClass('jwStatus').addClass('jwNoStatus');
		}

		// Set active flag
		objWindow.jw.hshOptions.blnHasStatus = blnValue;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Enables or disables the resizable grip
	 * @param boolean
	 * @param boolean		DEFAULTS to true
	 */
	setIsResizable: function(objWindow, blnValue, blnUpdateOptions) {
		// Set correct class
		if (blnValue) {
			// Add the status if it wasn't allready set
			if (!objWindow.jw.hshOptions.blnHasStatus) {
				jqWindow.setHasStatus(objWindow, true);
			}

			// Set the correct classname
			objWindow.jw.objqResize.removeClass('jwStatusR').addClass('jwStatusRR');

			// Set options
			hshOptions = {
				handlers: {
					se: '.jwStatusRR'
				},
				onStart: function() {
					// Set the active window
					jqWindow.setActive(objWindow);

					// Get correct offset for this window (scrollTop)
					hshTemp = {
						left: objWindow.jw.hshOptions.hshDimensions.left,
						top: objWindow.jw.hshOptions.hshDimensions.top,
						width: objWindow.jw.hshOptions.hshDimensions.width,
						height: objWindow.jw.hshOptions.hshDimensions.height
					}
					hshTemp = jqWindow.calcLeftTop(objWindow, hshTemp);

					// Add padding
					hshTemp.height+= objWindow.jw.intPadding;

					// Add helper
					jqWindow.objqHelper
						.addClass('jwResizing')
						.css({
								cursor: 'se-resize',
								left: hshTemp.left + 'px',
								top: hshTemp.top + 'px',
								width: hshTemp.width + 'px',
								height: hshTemp.height + 'px'
							}).show();
				},
				onResize: function(hshSize, hshPosition) {
					// Add padding
					intHeight = hshSize.height;
					intHeight+= objWindow.jw.intPadding;

					// Update dimensions
					jqWindow.objqHelper
						.css({
								left: hshPosition.left + 'px',
								top: hshPosition.top + 'px',
								width: hshSize.width + 'px',
								height: intHeight + 'px'
							});
				},
				onStop: function() {
					// Update dimensions
					hshDimensions = {
							left: parseInt(jqWindow.objqHelper.css('left')),
							top: parseInt(jqWindow.objqHelper.css('top')),
							width: parseInt(jqWindow.objqHelper.css('width')),
							height: (parseInt(jqWindow.objqHelper.css('height')) - objWindow.jw.intPadding)
					};
					jqWindow.setDimensions(objWindow, hshDimensions, true);

					// Hide helper
					jqWindow.objqHelper
						.removeClass('jwResizing')
						.css({
								cursor: 'default'
							}).hide();
				}
			};

			// Minimum width/height combination
			if (jqWindow.isHash(objWindow.jw.hshOptions.hshMinSize)) {
				hshOptions.minWidth = objWindow.jw.hshOptions.hshMinSize.width;
				hshOptions.minHeight = objWindow.jw.hshOptions.hshMinSize.height;
			}

			// Maximum width/height combination
			if (jqWindow.isHash(objWindow.jw.hshOptions.hshMaxSize)) {
				hshOptions.maxWidth = objWindow.jw.hshOptions.hshMaxSize.width;
				hshOptions.maxHeight = objWindow.jw.hshOptions.hshMaxSize.height;
			}

			// Create resizeable
			jQuery(objWindow).Resizable(hshOptions);
		} else {
			// Destroy resizable
			if (objWindow.jw.objqResize.is('.jwStatusRR')) {
				jQuery(objWindow).ResizableDestroy();

				// Remove classname
				objWindow.jw.objqResize.removeClass('jwStatusRR').addClass('jwStatusR');
			}
		}

		// Update the option hash? Default to true
		blnUpdateOptions = (blnUpdateOptions === false) ? false : true;
		if  (blnUpdateOptions) {
			objWindow.jw.hshOptions.blnIsResizable = blnValue;
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Enables or disables the draggable title bar
	 * @param boolean
	 * @param boolean		DEFAULTS to true
	 */
	setIsDraggable: function(objWindow, blnValue, blnUpdateOptions) {
		// Set correct class
		if (blnValue) {
			// Set options
			hshOptions = {
				handle: '.jwTitle',
				ghosting: true,
				onStart: function(objElement) {
					// Restrict to parent?
					if (objWindow.jw.hshOptions.blnIsRestricted) {
						hshClientInfo = jqWindow.getClientInfo();
						jQuery.iDrag.dragged.dragCfg.containment = [
								0,
								hshClientInfo.scrollTop,
								hshClientInfo.documentWidth,
								hshClientInfo.documentHeight
							];
					}

					// Set the active window
					jqWindow.setActive(objWindow);

					// Update the element
					strWidth = objWindow.jw.hshOptions.hshDimensions.width + 'px';
					strHeight = (objWindow.jw.intWindowState == -1) ? objElem.jw.objqTitleWrp.height() : (objWindow.jw.hshOptions.hshDimensions.height + objWindow.jw.intPadding) + 'px';
					jQuery(objElement).addClass('jwDragging').css({
							display: 'block',
							width: strWidth,
							height: strHeight
					}).html('&nbsp;');

					// Make sure the jwHelper class is on the helper, so it gets pushed on top.
					jQuery.iDrag.helper.addClass('jwHelper');
				},
				onStop: function() {
					// Initialize the new hash (with integers)
					hshTemp = {
						left: parseInt(jQuery(this).css('left')) || 0,
						top: parseInt(jQuery(this).css('top')) || 0,
						width: parseInt(objWindow.jw.hshOptions.hshDimensions.width) || 0,
						height: parseInt(objWindow.jw.hshOptions.hshDimensions.height) || 0
					};

					// Update the window position, and set the moved flag
					jqWindow.setDimensions(objWindow, hshTemp, true);
				}
			};

			// Create draggable
			jQuery(objWindow).Draggable(hshOptions);
		} else {
			// Destroy draggable
			jQuery(objWindow).DraggableDestroy();
		}

		// Update the option hash? Default to true
		blnUpdateOptions = (blnUpdateOptions === false) ? false : true;
		if  (blnUpdateOptions) {
			objWindow.jw.hshOptions.isDraggable = blnValue;
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Updates the title of the window
	 * @param	object
	 * @param	double
	 */
	setOpacity: function(objWindow, dblValue) {
		// Check opacity
		dblValue = parseFloat(dblValue);
		if (isNaN(dblValue))
			dblValue = 1.0;

		// Set new opacity
		jQuery(objWindow).css({
				opacity: dblValue
			});

		// Save new opacity
		objWindow.jw.hshOptions.dblOpacity = dblValue;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Updates the position of the window
	 * @param	object
	 * @param	integer
	 */
	setPosition: function(objWindow, intValue) {
		// Save new position
		objWindow.jw.hshOptions.intPosition = intValue;

		// Make sure the window has the right LEFT and TOP position
		jqWindow.setDimensions(objWindow, jqWindow.calcLeftTop(objWindow, objWindow.jw.hshOptions.hshDimensions));
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Updates the title of the window
	 * @param	object
	 * @param	string
	 */
	setTitle: function(objWindow, strValue) {
		objWindow.jw.objqTitle.html(strValue);
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Updates the content of the window with the new value
	 * @param	object
	 * @param	string
	 */
	setContent: function(objWindow, strValue) {
		// Make sure there is no iFrame anymore
		jqWindow.setIFrame(objWindow, false);

		// Set the new content
		objWindow.jw.objqContent.empty().html(strValue);

		// Execute the LOAD callback
		jqWindow.cbLoad(objWindow.jw.objqContent);
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Updates the content of the window with a new URL
	 * @param	object
	 * @param	string
	 * @param	boolean
	 */
	setContentURL: function(objWindow, strURL, blnUseIframe) {
		// Use an iframe for the content?
		blnUseIframe = (blnUseIframe === true) ? true : false;

		// Make sure the iFrame exists, (or doesn't) based upon the choice to use it
		jqWindow.setIFrame(objWindow, blnUseIframe);

		// Load correct content
		if (blnUseIframe == true) {
			// Set the right source
			objWindow.jw.objqIFrame[0].src = strURL;

			// Execute the LOAD callback
			objWindow.jw.objqIFrame.load(function() {
				jqWindow.cbLoad(jQuery(this).parent());
			});
		} else {
			// Use AJAX to load the information and use the window.setContent function to set new content
			jQuery.get(strURL, function(strValue) {
					jqWindow.setContent(objWindow, strValue);
				});
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Updates the statusbar of the window
	 * @param	object
	 * @param	string
	 */
	setStatus: function(objWindow, strValue) {
		if (strValue != '') {
			objWindow.jw.objqStatus
				.html(strValue)
				.css({
						fontSize: '',
						lineHeight: ''
					});
		} else {
			objWindow.jw.objqStatus
				.html('&nbsp;')
				.css({
						fontSize: '1px',
						lineHeight: '1px'
					});
		}
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Sets a window to be the active one. Also makes sure if there is an active current window, and it is
	 * modal that it remains on top.
	 * @param	DOM element
	 */
	setActive: function(objWindow) {
		blnHasActive = (jqWindow.objqActive !== null);
		blnSetActive = (!blnHasActive);

		// Only change the active window if:
		// - There is no active window
		// - The new window isn't modal
		// - The window is different then the normal one
		if (blnHasActive) {
			if (jqWindow.objqActive[0].jw.hshOptions.strName != objWindow.jw.hshOptions.strName) {
				// Remove resizable if there is one
				if (jqWindow.objqActive[0].jw.hshOptions.blnIsResizable) {
					jqWindow.setIsResizable(jqWindow.objqActive[0], false, false);
				}

				// If the current window is modal, make sure it remains on top.
				if (jqWindow.objqActive[0].jw.hshOptions.blnIsModal) {
					// The new window has a higher zIndex, so update this window
					if (jqWindow.objqActive[0].intZIndex < jqWindow.intZIndex) {
						// Increase the zIndex
						jqWindow.objqActive[0].intZIndex = jqWindow.newZIndex();

						// Update the window
						jqWindow.checkZIndex(jqWindow.objqActive[0]);
					}
				} else {
					jqWindow.objqActive.removeClass('jwActive');
					blnSetActive = true;
				}
			}
		}

		// If we have to update this window to be the active one
		if (blnSetActive) {
			// Change active state
			jqWindow.objqActive = jQuery(objWindow);
			jqWindow.objqActive.addClass('jwActive');

			// Increase the zIndex
			objWindow.jw.intZIndex = jqWindow.newZIndex();

			// Update the overlay of needed
			jqWindow.setIsModal(objWindow, objWindow.jw.hshOptions.blnIsModal);

			// Update resizable if there is one
			jqWindow.setIsResizable(objWindow, objWindow.jw.hshOptions.blnIsResizable, false);

			// Update the window
			jqWindow.checkZIndex(objWindow);
		}

		// Show the window
		jQuery(objWindow).show();

		// Update padding
		jqWindow.updatePadding(objWindow);
		jqWindow.setOffset(objWindow, objWindow.jw.hshOptions.hshDimensions);
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Builds the window
	 * @param	object		DOM element to change
	 * @param	array		Hash with the options
	 */
	build: function(cfgOptions) {
		//----------------------------------------------------------------------------------------------------
		// Check for required plugins
		//----------------------------------------------------------------------------------------------------
		// Test for interface code
		if (!jQuery.iUtil || !jQuery.iDrag || !jQuery.iResize) {
			alert('Unable to find required the "interface" code!\nMake sure you have loaded both iUtil, iDrag and iResizable.');
			return false;
		}

		//----------------------------------------------------------------------------------------------------
		// First window to be created?
		//----------------------------------------------------------------------------------------------------
		if (jqWindow.blnInitialized == false) {
			// Set initialized flag
			jqWindow.blnInitialized = true;

			// Create helper (for resizing and transferring)
			jqWindow.objqHelper = jQuery('<div class="jwHelper">&nbsp;</div>');
			jQuery('body', document).append(jqWindow.objqHelper);

			// Assign document event handlers
			jQuery(window).scroll(jqWindow.updateWindows);
			jQuery(window).resize(jqWindow.updateWindows);
			jQuery(document).focus(jqWindow.focusHandler);
		}

		//----------------------------------------------------------------------------------------------------
		// Create the window object. We assign all functionality to this object for code simplification.
		//----------------------------------------------------------------------------------------------------
		objqElem = jQuery(document.createElement('div'));
		objElem = objqElem[0];


		//----------------------------------------------------------------------------------------------------
		// Initialize the default properties of this object
		//----------------------------------------------------------------------------------------------------
		objElem.jw = new function() {
				this.blnInitialized = false;			// To prevent multiple calls to various functions when building
				this.blnIsMoved = false;					// helper
				this.blnIsResizable = false;			// helper
				this.blnIsDraggable = false;			// helper
				this.hshViewState = null;					// Holds size information needed by maximize / minimize functions
				this.objqOverlay = null;					// Variable for the overlay object
				this.objqBtnMinimize = null;			// Variable for the minimize button
				this.objqBtnMaximize = null;			// Variable for the maximize button
				this.objqBtnClose = null;					// Variable for the close button
				this.objqIFrame = null;						// Variable for the content iFrame
				this.objqContent = null;					// Variable for the content DIV
				this.intZIndex = 500;							// Dummy value, gets overwritten
				this.intWindowState = 0;					// Window state
				this.intPadding = 0;							// For resizable

				// Define default options and override them with the passed configuration, if available
				this.hshOptions = jQuery.extend({
						strName: 'myWindow',					// The name of the window
						strTheme: 'Default',					// The theme to use
						hshDimensions: {							// An hash with initial offsets
								left: 0,
								top: 0,
								width: 500,
								height: 400
							},
						hshMinSize: null,							// A hash with a minimum size (width/height)
						hshMaxSize: null,							// A hash with a maximum size (width/height)
						blnIsModal: false,						// Show an overlay and prefect focus out of the window?
						blnHasMinimize: true,					// If the window has a minimize button
						intMimimizedWidth: 200,				// The width of the titlebar when minimized
						blnHasMaximize: true,					// If the window has a maximize button
						blnHasClose: true,						// If the window has a close button
						blnHasStatus: true,						// If the window has a status bar
						blnIsDraggable: true,					// Indicates if the window is draggable
						blnIsResizable: true,					// Indicates if the window is resizable
						blnTransfer: false,						// If the window uses the transferto effect
						intPosition: 0,								// Position untill moved: default (0), center screen (1)
						blnIsRestricted: true,				// Is the element restricted to the parent?
						intInitialSate: 0,						// Initial state: minimized (-1), default (0), maximized (1)
						dblOpacity: 1.0,							// The opacity of the dialog
						strTitle: 'Title',						// ...
						strContent: '&nbsp;',					// ...
						strStatus: ''									// ...
					}, cfgOptions || {});
			};

		//----------------------------------------------------------------------------------------------------
		// Make sure we don't build the element twice, check if there is a window object with an options hash.
		//----------------------------------------------------------------------------------------------------
		objqTemp = jqWindow.getByName(objElem.jw.hshOptions.strName);
		if (objqTemp) {
			// Move window to front
			jqWindow.setActive(objqTemp[0]);

			// Free the handle of the DOM object
			objElem = null;

			// Return the old object
			return objqTemp;
		}
		objqTemp = null;


		//----------------------------------------------------------------------------------------------------
		// Transfer effect: Check to see if it is supported and add the helper object if needed.
		//----------------------------------------------------------------------------------------------------
		objElem.jw.hshOptions.blnTransfer = (objElem.jw.hshOptions.blnTransfer && jQuery.fx.itransferTo) ? true: false;


		//----------------------------------------------------------------------------------------------------
		// Check sizes
		//----------------------------------------------------------------------------------------------------
		if (!jqWindow.isHash(objElem.jw.hshOptions.hshMinSize)) {
			objElem.jw.hshOptions.hshMinSize = null;
		}

		if (!jqWindow.isHash(objElem.jw.hshOptions.hshMaxSize)) {
			objElem.jw.hshOptions.hshMaxSize = null;
		}

		// Make sure the minimum size is not larger then the maximum size and vice versa
		if (jqWindow.isHash(objElem.jw.hshOptions.hshMinSize) && jqWindow.isHash(objElem.jw.hshOptions.hshMaxSize)) {
			// Check minimum width
			if (objElem.jw.hshOptions.hshMinSize.width > objElem.jw.hshOptions.hshMaxSize.width) {
					objElem.jw.hshOptions.hshMinSize.width = objElem.jw.hshOptions.hshMaxSize.width;
			}

			// Check minimum height
			if (objElem.jw.hshOptions.hshMinSize.height > objElem.jw.hshOptions.hshMaxSize.height) {
				objElem.jw.hshOptions.hshMinSize.height = objElem.jw.hshOptions.hshMaxSize.height;
			}

			// Check maximum width
			if (objElem.jw.hshOptions.hshMaxSize.width < objElem.jw.hshOptions.hshMinSize.width) {
					objElem.jw.hshOptions.hshMaxSize.width = objElem.jw.hshOptions.hshMinSize.width;
			}

			// Check maximum height
			if (objElem.jw.hshOptions.hshMaxSize.height < objElem.jw.hshOptions.hshMinSize.height) {
				objElem.jw.hshOptions.hshMaxSize.height = objElem.jw.hshOptions.hshMinSize.height;
			}
		}


		//----------------------------------------------------------------------------------------------------
		// Set the name of the window object
		//----------------------------------------------------------------------------------------------------
		objqElem.id(objElem.jw.hshOptions.strName).hide();
		jQuery('body', document).append(objqElem);


		//----------------------------------------------------------------------------------------------------
		// Make sure this window has a new zIndex
		//----------------------------------------------------------------------------------------------------
		objElem.jw.intZIndex = jqWindow.newZIndex();


		//----------------------------------------------------------------------------------------------------
		// Build the window
		//----------------------------------------------------------------------------------------------------
		// The reason for 3 different tables are simple:
		// * If we use CSS we have a lot of problems setting the sizes of the border graphics
		// * If we use 1 table with 9 cells (tic-tac-toe) and add an iframe for the URL,
		//   the table gets screwed up in IE (should have guessed that) :p
		//   Theseame happens if we add a new table in the center of the 3x3 square.
		//----------------------------------------------------------------------------------------------------
		var strHTML = '';

		// Add the button wrap
		strHTML+= '<div class="btnWrap"></div>';

		// Add the header part
		strHTML+= '<table cellspacing="0" cellpadding="0" border="0" class="jwTitle">';
			strHTML+= '<tr>';
			strHTML+= '<td class="jwTitleL">&nbsp;</td>';
			strHTML+= '<td class="jwTitleC">&nbsp;</td>';
			strHTML+= '<td class="jwTitleR">&nbsp;</td>';
			strHTML+= '</tr>';
		strHTML+= '</table>';

		// Add the content part
		strHTML+= '<table cellspacing="0" cellpadding="0" border="0" class="jwContent">';
			strHTML+= '<tr>';
			strHTML+= '<td class="jwContentL">&nbsp;</td>';
			strHTML+= '<td class="jwContentC">&nbsp;</td>';
			strHTML+= '<td class="jwContentR">&nbsp;</td>';
			strHTML+= '</tr>';
		strHTML+= '</table>';

		// Add the footer
		strHTML+= '<table cellspacing="0" cellpadding="0" border="0" class="jwStatus">';
			strHTML+= '<tr>';
			strHTML+= '<td class="jwStatusL">&nbsp;</td>';
			strHTML+= '<td class="jwStatusC">&nbsp;</td>';
			strHTML+= '<td class="jwStatusR">&nbsp;</td>';
			strHTML+= '</tr>';
		strHTML+= '</table>';

		// Assign the HTML
		objqElem
			.html(strHTML)
			.css({
					position: 'absolute',
					zIndex: objElem.jw.intZIndex,
					textAlign: 'left'
				});


		//----------------------------------------------------------------------------------------------------
		// Get a handle to the objects we just created
		//----------------------------------------------------------------------------------------------------
		objElem.jw.objqButtonWrp = jQuery('.btnWrap', objqElem);
		objElem.jw.objqTitleWrp = jQuery('.jwTitle', objqElem).css({ width: '100%' });
		objElem.jw.objqContentWrp = jQuery('.jwContent', objqElem).css({ width: '100%' });
		objElem.jw.objqStatusWrp = jQuery('.jwStatus', objqElem).css({ width: '100%' });

		// Content parts
		objElem.jw.objqTitle = jQuery('.jwTitleC', objElem.jw.objqTitleWrp);
		objElem.jw.objqStatus = jQuery('.jwStatusC', objElem.jw.objqStatusWrp);

		// Resize grip
		objElem.jw.objqResize = jQuery('.jwStatusR', objElem.jw.objqStatusWrp);

		//  Fix the CSS styling: width/height of the corners of the windows (by setting these CSS params)
		jQuery('.jwTitleL,.jwTitleR,.jwContentL,.jwContentR,.jwStatusL,.jwStatusR', objqElem).css({
				fontSize: '1px',
				lineHeight: '1px'
			});

		// Disable selecting of the text in both the title and the statusbar
		if (jQuery.browser.mozilla) {
			jQuery.each( [ objElem.jw.objqTitleWrp, objElem.jw.objqStatusWrp ], function() {
					this.css({ '-moz-user-select': 'none' });
				});
		} else {
			jQuery.each( [ objElem.jw.objqTitleWrp, objElem.jw.objqStatusWrp ], function() {
					this.bind('selectstart', function() {
							return false;
						});
				});
		}


		//----------------------------------------------------------------------------------------------------
		// Set correct window content
		//----------------------------------------------------------------------------------------------------
		jqWindow.setTheme(objElem, objElem.jw.hshOptions.strTheme);
		jqWindow.setTitle(objElem, objElem.jw.hshOptions.strTitle);
		jqWindow.setContent(objElem, objElem.jw.hshOptions.strContent);
		jqWindow.setStatus(objElem, objElem.jw.hshOptions.strStatus);


		//----------------------------------------------------------------------------------------------------
		// Set correct window layout
		//----------------------------------------------------------------------------------------------------
		jqWindow.setIsModal(objElem, objElem.jw.hshOptions.blnIsModal);
		jqWindow.setHasMinimize(objElem, objElem.jw.hshOptions.blnHasMinimize);
		jqWindow.setHasMaximize(objElem, objElem.jw.hshOptions.blnHasMaximize);
		jqWindow.setHasClose(objElem, objElem.jw.hshOptions.blnHasClose);
		jqWindow.setHasStatus(objElem, objElem.jw.hshOptions.blnHasStatus);
		jqWindow.setIsDraggable(objElem, objElem.jw.hshOptions.blnIsDraggable);
		jqWindow.setIsResizable(objElem, objElem.jw.hshOptions.blnIsResizable);
		jqWindow.setOpacity(objElem, objElem.jw.hshOptions.dblOpacity);
		jqWindow.setPosition(objElem, objElem.jw.hshOptions.intPosition);

		// Set correct state
		if (objElem.jw.hshOptions.intInitialState == -1) {
			jqWindow.doMinimize(objWindow, false);
		} else if (objElem.jw.hshOptions.intInitialState == 1) {
			jqWindow.doMaximize(objWindow, false);
		}


		//----------------------------------------------------------------------------------------------------
		// Click handler
		//----------------------------------------------------------------------------------------------------
		objqElem.click(function() {
			// Make the dialog active
			jqWindow.setActive(this);
		});


		//----------------------------------------------------------------------------------------------------
		// Done building
		//----------------------------------------------------------------------------------------------------
		objElem.jw.blnInitialized = true;


		//----------------------------------------------------------------------------------------------------
		// Save window
		//----------------------------------------------------------------------------------------------------
		jqWindow.arrWindows[jqWindow.arrWindows.length] = objqElem;


		//----------------------------------------------------------------------------------------------------
		// Try to make this window active
		//----------------------------------------------------------------------------------------------------
		jqWindow.setActive(objElem);


		//----------------------------------------------------------------------------------------------------
		// Add iframe hack
		//----------------------------------------------------------------------------------------------------
		objqElem.bgiframe();

		return objqElem;
	},

	//----------------------------------------------------------------------------------------------------

	/**
	 * Removes the window completely
	 * @param	DOM element
	 */
	destroy: function(objWindow) {
		objqWindow = jQuery(objWindow);

		// Perform the callback
		jqWindow.doCallback(objWindow.jw.hshOptions.onClose, objWindow);

		// Remove the overlay
		jqWindow.setIsModal(objWindow, false);

		// Remove connection to the current object if that is thesame
		if (jqWindow.objqActive && (objWindow.jw.hshOptions.strName == jqWindow.objqActive[0].jw.hshOptions.strName))
			jqWindow.objqActive = null;

		// Remove the element from the array
		jqWindow.removeByName(objWindow.jw.hshOptions.strName);

		// Remove the window itself
		objqWindow.unbind().remove();
	}
};

//
// Initialize the object
jqWindow = new jqWindow();
