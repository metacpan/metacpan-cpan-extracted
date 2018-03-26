// version: 2017-11-25
    /**
    * o--------------------------------------------------------------------------------o
    * | This file is part of the RGraph package - you can learn more at:               |
    * |                                                                                |
    * |                          http://www.rgraph.net                                 |
    * |                                                                                |
    * | RGraph is licensed under the Open Source MIT license. That means that it's     |
    * | totally free to use and there are no restrictions on what you can do with it!  |
    * o--------------------------------------------------------------------------------o
    */

    RGraph = window.RGraph || {isRGraph: true};




// Module pattern
(function (win, doc, undefined)
{
    var RG  = RGraph,
        ua  = navigator.userAgent,
        ma  = Math;




    /**
    * This is used in two functions, hence it's here
    */
    RG.tooltips     = {};
    RG.tooltips.style = {
        display:    'inline-block',
        position:   'absolute',
        padding:    '6px',
        fontFamily: 'Arial',
        fontSize:   '10pt',
        fontWeight: 'normal',
        textAlign:  'center',
        left:       0,
        top:        0,
        backgroundColor: 'rgb(255,255,239)',
        color:      'black',
        visibility: 'visible',
        zIndex:     3,
        borderRadius: '5px',
        boxShadow:  'rgba(96,96,96,0.5) 0 0 5px',
        opacity:    0
    };



    /**
    * Shows a tooltip next to the mouse pointer
    * 
    * @param canvas object The canvas element object
    * @param text   string The tooltip text
    * @param int     x      The X position that the tooltip should appear at. Combined with the canvases offsetLeft
    *                       gives the absolute X position
    * @param int     y      The Y position the tooltip should appear at. Combined with the canvases offsetTop
    *                       gives the absolute Y position
    * @param int     idx    The index of the tooltip in the graph objects tooltip array
    * @param object  e      The event object
    */
    RG.tooltip =
    RG.Tooltip = function (obj, text, x, y, idx, e)
    {
        if (RG.trim(text).length === 0) {
            return;
        }



        /**
        * Fire the beforetooltip event
        */
        RG.fireCustomEvent(obj, 'onbeforetooltip');



        /**
        * chart.tooltip.override allows you to totally take control of rendering the tooltip yourself
        */
        if (typeof(obj.get('chart.tooltips.override')) == 'function') {
            return obj.get('chart.tooltips.override')(obj, text, x, y, idx);
        }




        /**
        * Save the X/Y coords
        */
        var originalX = x;
        var originalY = y;

        /**
        * This facilitates the "id:xxx" format
        */
        text = RG.getTooltipTextFromDIV(text);

        /**
        * First clear any exising timers
        */
        var timers = RG.Registry.Get('chart.tooltip.timers');

        if (timers && timers.length) {
            for (i=0; i<timers.length; ++i) {
                clearTimeout(timers[i]);
            }
        }
        RG.Registry.Set('chart.tooltip.timers', []);

        /**
        * Hide the context menu if it's currently shown
        */
        if (obj.get('chart.contextmenu')) {
            RG.hideContext();
        }



        /**
        * Show a tool tip
        */
        var tooltipObj       = document.createElement('DIV');
        tooltipObj.className = obj.get('chart.tooltips.css.class');

        // Add the default CSS to the tooltip
        for (var i in RGraph.tooltips.style) {
            if (typeof i === 'string') {
                tooltipObj.style[i] = RGraph.tooltips.style[i];
            }
        }

        tooltipObj.innerHTML                = text;
        tooltipObj.__text__                 = text; // This is set because the innerHTML can change when it's set
        tooltipObj.__canvas__               = obj.canvas;
        tooltipObj.id                       = '__rgraph_tooltip_' + obj.canvas.id + '_' + obj.uid + '_'+ idx;
        tooltipObj.__event__                = obj.Get('chart.tooltips.event') || 'click';
        tooltipObj.__object__               = obj;

        if (typeof idx === 'number') {
            tooltipObj.__index__ = idx;
            origIdx = idx;
        }

        if (obj.type === 'line' || obj.type === 'radar') {
            for (var ds=0; ds<obj.data.length; ++ds) {
                if (idx >= obj.data[ds].length) {
                    idx -= obj.data[ds].length;
                } else {
                    break;
                }
            }
            
            tooltipObj.__dataset__ = ds;
            tooltipObj.__index2__  = idx;
        }

        document.body.appendChild(tooltipObj);
        //obj.canvas.parentNode.appendChild(tooltipObj);

        var width  = tooltipObj.offsetWidth;
        var height = tooltipObj.offsetHeight;


        /**
        * Set the width on the tooltip so it doesn't resize if the window is resized
        */
        tooltipObj.style.width = width + 'px';









        //
        // position the tooltip on the mouse pointers position
        //
        var mouseXY  = RG.getMouseXY(e);
        var canvasXY = RG.getCanvasXY(obj.canvas);

        // Position based on the mouse pointer coords on the page
        tooltipObj.style.left = e.pageX - (parseFloat(tooltipObj.style.paddingLeft) + (width / 2)) + 'px';
        tooltipObj.style.top  = e.pageY - height - 10 + 'px';
        
        // If the left is less than zero - set it to 5
        if (parseFloat(tooltipObj.style.left) <= 5) {
            tooltipObj.style.left = '5px';
        }

        // If the tooltip goes over the right hand edge then
        // adjust the positioning
        if (parseFloat(tooltipObj.style.left) + parseFloat(tooltipObj.style.width) > window.innerWidth) {
            tooltipObj.style.left  = ''
            tooltipObj.style.right = '5px'
        }
        
        // If the canvas has fixed positioning then set the tooltip position to
        // fixed too
        if (RG.isFixed(obj.canvas)) {
            var scrollTop = window.scrollY || document.documentElement.scrollTop;

            tooltipObj.style.position = 'fixed';
            tooltipObj.style.top = e.pageY - scrollTop - height - 10 + 'px';
        }
        
        
        
        
        
        
        // If the effect is fade:
        // Increase the opacity from its default 0 up to 1 - fading the tooltip in
        if (obj.get('chart.tooltips.effect') === 'fade') {
            for (var i=1; i<=10; ++i) {
                (function (index)
                {
                    setTimeout(function ()
                    {
                        tooltipObj.style.opacity = index / 10;
                    }, index * 25);
                })(i);
            }
        } else {
            tooltipObj.style.opacity = 1;
        }











        /**
        * If the tooltip it self is clicked, cancel it
        */
        tooltipObj.onmousedown = function (e){e.stopPropagation();}
        tooltipObj.onmouseup   = function (e){e.stopPropagation();}
        tooltipObj.onclick     = function (e){if (e.button == 0) {e.stopPropagation();}}







        /**
        * Keep a reference to the tooltip in the registry
        */
        RG.Registry.Set('chart.tooltip', tooltipObj);

        /**
        * Fire the tooltip event
        */
        RG.fireCustomEvent(obj, 'ontooltip');
    };




    /**
    * 
    */
    RG.getTooltipTextFromDIV = function (text)
    {
        // This regex is duplicated firher down on roughly line 888
        var result = /^id:(.*)/.exec(text);

        if (result && result[1] && document.getElementById(result[1])) {
            text = document.getElementById(result[1]).innerHTML;
        } else if (result && result[1]) {
            text = '';
        }
        
        return text;
    };




    /**
    * 
    */
    RG.getTooltipWidth = function (text, obj)
    {
        var div = document.createElement('DIV');
            div.className             = obj.Get('chart.tooltips.css.class');
            div.style.paddingLeft     = RG.tooltips.padding;
            div.style.paddingRight    = RG.tooltips.padding;
            div.style.fontFamily      = RG.tooltips.font_face;
            div.style.fontSize        = RG.tooltips.font_size;
            div.style.visibility      = 'hidden';
            div.style.position        = 'absolute';
            div.style.top            = '300px';
            div.style.left             = 0;
            div.style.display         = 'inline';
            div.innerHTML             = RG.getTooltipTextFromDIV(text);
        document.body.appendChild(div);

        return div.offsetWidth;
    };




    /**
    * Hides the currently shown tooltip
    */
    RG.hideTooltip =
    RG.HideTooltip = function ()
    {
        var tooltip = RG.Registry.Get('chart.tooltip');
        var uid     = arguments[0] && arguments[0].uid ? arguments[0].uid : null;

        if (tooltip && tooltip.parentNode && (!uid || uid == tooltip.__canvas__.uid)) {
            tooltip.parentNode.removeChild(tooltip);
            tooltip.style.display = 'none';                
            tooltip.style.visibility = 'hidden';
            RG.Registry.Set('chart.tooltip', null);
        }
    };




    /**
    * This (as the name suggests preloads any images it can find in the tooltip text
    * 
    * @param object obj The chart object
    */
    RG.preLoadTooltipImages =
    RG.PreLoadTooltipImages = function (obj)
    {
        var tooltips = obj.Get('chart.tooltips');
        
        if (RG.hasTooltips(obj)) {
        
            if (obj.type == 'rscatter') {
                tooltips = [];
                for (var i=0; i<obj.data.length; ++i) {
                    tooltips.push(obj.data[3]);
                }
            }
            
            for (var i=0; i<tooltips.length; ++i) {
                // Add the text to an offscreen DIV tag
                var div = document.createElement('DIV');
                    div.style.position = 'absolute';
                    div.style.opacity = 0;
                    div.style.top = '-100px';
                    div.style.left = '-100px';
                    div.innerHTML  = tooltips[i];
                document.body.appendChild(div);
                
                // Now get the IMG tags and create them
                var img_tags = div.getElementsByTagName('IMG');
    
                // Create the image in an off-screen image tag
                for (var j=0; j<img_tags.length; ++j) {
                        if (img_tags && img_tags[i]) {
                        var img = document.createElement('IMG');
                            img.style.position = 'absolute';
                            img.style.opacity = 0;
                            img.style.top = '-100px';
                            img.style.left = '-100px';
                            img.src = img_tags[i].src
                        document.body.appendChild(img);
                        
                        setTimeout(function () {document.body.removeChild(img);}, 250);
                    }
                }
    
                // Now remove the div
                document.body.removeChild(div);
            }
        }
    };




    /**
    * This is the tooltips canvas onmousemove listener
    */
    RG.tooltips_mousemove =
    RG.Tooltips_mousemove = function (obj, e)
    {
        var shape = obj.getShape(e);
        var changeCursor_tooltips = false

        if (   shape
            && typeof(shape['index']) == 'number'
            && obj.Get('chart.tooltips')[shape['index']]
           ) {

            var text = RG.parseTooltipText(obj.Get('chart.tooltips'), shape['index']);

            if (text) {

                /**
                * Change the cursor
                */
                changeCursor_tooltips = true;

                if (obj.Get('chart.tooltips.event') == 'onmousemove') {

                    // Show the tooltip if it's not the same as the one already visible
                    if (
                           !RG.Registry.Get('chart.tooltip')
                        || RG.Registry.Get('chart.tooltip').__object__.uid != obj.uid
                        || RG.Registry.Get('chart.tooltip').__index__ != shape['index']
                       ) {

                        RG.hideTooltip();
                        RG.Clear(obj.canvas);
                        RG.redraw();
                        RG.tooltip(obj, text, e.pageX, e.pageY, shape['index']);
                        obj.Highlight(shape);
                    }
                }
            }
        
        /**
        * More highlighting
        */
        } else if (shape && typeof(shape['index']) == 'number') {

            var text = RG.parseTooltipText(obj.Get('chart.tooltips'), shape['index']);

            if (text) {
                changeCursor_tooltips = true
            }
        }

        return changeCursor_tooltips;
    };




// End module pattern
})(window, document);