/**
 * Creates a button from an image element.
 *
 * This function attempts to mimic the functionality of the "button" found in
 * modern day GUIs. There are two different buttons you can create using this
 * plugin; Normal buttons, and Toggle buttons.
 *
 * @name button
 * @type jQuery
 * @param hOptions   hash with options, described below.
 *                   sPath      Full path to the images, either relative or
 *                              with full URL
 *                   sExt       Extension of the used images (jpg|gif|png)
 *                   sName      Name of the button, if not specified, try to
 *                              fetch from id
 *                   iWidth     Width of the button, if not specified, try to
 *                              fetch from element.width
 *                   iHeight    Height of the button, if not specified, try to
 *                              fetch from element.height
 *                   onAction   Function to call when clicked / toggled. In
 *                              case of a string, the element is wrapped inside
 *                              an href tag.
 *                   bToggle    Do we need to create a togglebutton? (boolean)
 *                   bState     Initial state of the button? (boolean)
 *                   sType      Type of hover to create (img|css)
 * @return jQuery
 * @cat Plugins/Button
 * @author Gilles van den Hoven
 * @author John Resig
 */
jQuery.fn.button = function(hOptions) {
	// Initialize option hash
	if (!hOptions) hOptions = {};
		
	return this.each(function(){

		// Gather configuration
		var cfgButton = {
			sPath: hOptions.sPath ? hOptions.sPath : '',
			sExt: hOptions.sExt ? hOptions.sExt : 'gif',
			sName: hOptions.sName ? hOptions.sName : (this.id ? this.id : ''),
			iWidth: hOptions.iWidth ? parseInt(hOptions.iWidth) || 0 :
				(this.width ? parseInt(this.width) || 0 : false),
			iHeight: hOptions.iHeight ? parseInt(hOptions.iHeight) || 0 :
				(this.height ? parseInt(this.height) || 0 : false),
			onAction: hOptions.onAction && 
				(hOptions.onAction.constructor == Function || hOptions.onAction.constructor == String) ?
					hOptions.onAction : false,
			bToggle: hOptions.bToggle ? hOptions.bToggle : false,
			bState: hOptions.bState ? hOptions.bState : false,
			sType: hOptions.sType ? hOptions.sType : 'img'
		};
	
		// Check type (CSS style or old-school IMG style
		if (cfgButton.sType != 'css' && cfgButton.sType != 'img')
			cfgButton.sType = 'img';
	
		// Check path
		if (cfgButton.sPath != '' && cfgButton.sPath.charAt(cfgButton.sPath.length) != '/')
			cfgButton.sPath+= '/';
	
		// Check action
		if (cfgButton.onAction.constructor == String)
			this.css( { border: 'none' } )
				.wrap('<a href="' + cfgButton.onAction + '" title="' + (this.title || '') + '"></a>');
	
		// Set cursor
		this.style.cursor = 'pointer';
	
		// Create images
		var imgOff = new Image, imgOver = new Image, imgDown = new Image;
	
		// Assign images
		if (cfgButton.sType == 'img') {
			imgOff.src = cfgButton.sPath + '/' + cfgButton.sName + '_off.' + cfgButton.sExt;
			imgOver.src = cfgButton.sPath + '/' + cfgButton.sName + '_over.' + cfgButton.sExt;
			imgDown.src = cfgButton.sPath + '/' + cfgButton.sName + '_down.' + cfgButton.sExt;
	
			// Set correct image
			this.src = imgOff.src;
	
			// Actions
			this.mouseout(function() {
				this.src = cfgButton.bToggle && cfgButton.bState ? imgDown.src : imgOff.src;
			}).mouseover(function() {
				this.src = imgOver.src;
			}).mousedown(function() {
				cfgButton.bState = (!cfgButton.bState);
				this.src = imgDown.src;
			}).mouseup(function() {
				this.src = cfgButton.bToggle && cfgButton.bState ? imgDown.src : imgOver.src;
			}).click(function() {
				if ( cfgButton.onAction )
					cfgButton.onAction(cfgButton.bState);
			});
		} else if (cfgButton.sType == 'css') {
			// In this case we need iWidth and iHeight filled
			if (!cfgButton.iWidth || !cfgButton.iHeight) {
				alert('the CSS button type requires iWidth and iHeight filled, either \n' + 
					'in the passed parameters, or as property of the image.');
				return;
			}
	
			// Calculate positions
			var sCssOff = '0px 0px', 
				sCssOver = '0px -' + cfgButton.iHeight + 'px',
				sCssDown = '0px -' + (cfgButton.iHeight * 2) + 'px';
	
			// Set correct image
			this.src = cfgButton.sPath + '/blank.gif';
			this.style.backgroundImage = 'url("' + cfgButton.sPath + '/' + cfgButton.sName + '.' + 
				cfgButton.sExt + '")';
			this.style.backgroundPosition = cfgButton.bToggle && cfgButton.bState ? sCssDown : sCssOff;
	
			// Actions
			this.mouseout(function() {
				this.style.backgroundPosition = cfgButton.bToggle && cfgButton.bState ? sCssDown : sCssOff;
			}).mouseover(function() {
				this.style.backgroundPosition = sCssOver;
			}).mousedown(function() {
				cfgButton.bState = !cfgButton.bState;
				this.style.backgroundPosition = sCssDown;
			}).mouseup(function() {
				this.style.backgroundPosition = cfgButton.bToggle && cfgButton.bState ? sCssDown : sCssOver;
			}).click(function() {
				if ( cfgButton.onAction )
					cfgButton.onAction(cfgButton.bState);
			});
		}
	});
};
