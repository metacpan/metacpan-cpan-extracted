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

    RGraph     = window.RGraph || {isRGraph: true,isRGraphSVG: true};
    RGraph.SVG = RGraph.SVG || {};

// Module pattern
(function (win, doc, undefined)
{
    var RG  = RGraph,
        ua  = navigator.userAgent,
        ma  = Math;



    /**
    * This is used in two functions, hence it's here
    */
    RG.SVG.tooltips       = {};
    RG.SVG.tooltips.style = {
        display:    'inline-block',
        position:   'absolute',
        padding:    '6px',
        fontFamily: 'Arial',
        fontSize:   '12pt',
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
        transition: 'left ease-out .25s, top ease-out .25s'
    };


    //
    // Shows a tooltip
    //
    // @param obj The chart object
    // @param opt The options
    //
    RG.SVG.tooltip = function (opt)
    {
        var obj = opt.object;

        // Fire the beforetooltip event
        RG.SVG.fireCustomEvent(obj, 'onbeforetooltip');


        if (!opt.text || typeof opt.text === 'undefined' || RG.SVG.trim(opt.text).length === 0) {
            return;
        }



        var prop = obj.properties;



        /**
        * chart.tooltip.override allows you to totally take control of rendering the tooltip yourself
        */
        if (typeof prop.tooltipsOverride === 'function') {

            // Add the body click handler that clears the highlight if necessary
            //
            document.body.addEventListener('mouseup', function (e)
            {
                obj.removeHighlight();
            }, false);

            return (prop.tooltipsOverride)(obj, opt);
        }








        // Create the tooltip DIV element
        if (!RG.SVG.REG.get('tooltip')) {

            var tooltipObj        = document.createElement('DIV');
            tooltipObj.className  = prop.tooltipsCssClass;
    
    
    
    
            // Add the default CSS to the tooltip
            for (var i in RG.SVG.tooltips.style) {
                if (typeof i === 'string') {
                    tooltipObj.style[i] = RG.SVG.tooltips.style[i];
                }
            }





        // Reuse an existing tooltip
        } else {
            var tooltipObj = RG.SVG.REG.get('tooltip');
            tooltipObj.__object__.removeHighlight();
            
            // This prevents the object from continuously growing
            tooltipObj.style.width = '';
        }

















        if (RG.SVG.REG.get('tooltip-lasty')) {
            tooltipObj.style.left = RG.SVG.REG.get('tooltip-lastx') + 'px';
            tooltipObj.style.top  = RG.SVG.REG.get('tooltip-lasty') + 'px';
        }

        tooltipObj.innerHTML  = opt.text;
        tooltipObj.__text__   = opt.text; // This is set because the innerHTML can change when it's set
        tooltipObj.id         = '__rgraph_tooltip_' + obj.id + '_' + obj.uid + '_'+  opt.index;
        tooltipObj.__event__  = prop.tooltipsEvent || 'click';
        tooltipObj.__object__ = obj;

        // Add the index
        if (typeof opt.index === 'number') {
            tooltipObj.__index__ = opt.index;
        }

        // Add the dataset
        if (typeof opt.dataset === 'number') {
            tooltipObj.__dataset__ = opt.dataset;
        }

        // Add the group
        if (typeof opt.group === 'number' || RG.SVG.isNull(opt.group)) {
            tooltipObj.__group__ = opt.group;
        }

        // Add the sequentialIndex
        if (typeof opt.sequentialIndex === 'number') {
            tooltipObj.__sequentialIndex__ = opt.sequentialIndex;
        }




        // Add the tooltip to the document
        document.body.appendChild(tooltipObj);
        
        
        var width  = tooltipObj.offsetWidth,
            height = tooltipObj.offsetHeight;

        // Move the tooltip into position
        tooltipObj.style.left = opt.event.pageX - (width / 2) + 'px';
        tooltipObj.style.top  = opt.event.pageY - height - 15 + 'px';




        /**
        * Set the width on the tooltip so it doesn't resize if the window is resized
        */
        tooltipObj.style.width = width + 'px';

        // Fade the tooltip in if the tooltip is not the first view
        if (!RG.SVG.REG.get('tooltip-lastx')) {
            for (var i=0; i<=30; ++i) {
                (function (idx)
                {
                    setTimeout(function ()
                    {
                        tooltipObj.style.opacity = (idx / 30) * 1;
                    }, (idx / 30) * 200);
                })(i);
            }
        }




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
        if (RG.SVG.isFixed(obj.svg)) {
            var scrollTop = window.scrollY || document.documentElement.scrollTop;

            tooltipObj.style.position = 'fixed';
            tooltipObj.style.top      = opt.event.pageY - scrollTop - height - 10 + 'px';
        }



        // Cancel the mousedown event
        tooltipObj.onmousedown = function (e)
        {
            e.stopPropagation();
        };

        // Cancel the mouseup event
        tooltipObj.onmouseup = function (e)
        {
            e.stopPropagation();
        };

        // Cancel the click event
        tooltipObj.onclick  = function (e)
        {
            if (e.button == 0) {
                e.stopPropagation();
            }
        };
        
        // Add the body click handler that clears the tooltip
        document.body.addEventListener('mouseup', function (e)
        {
            RG.SVG.hideTooltip();
        }, false);





        /**
        * Keep a reference to the tooltip in the registry
        */
        RG.SVG.REG.set('tooltip', tooltipObj);
        RG.SVG.REG.set('tooltip-lastx', parseFloat(tooltipObj.style.left));
        RG.SVG.REG.set('tooltip-lasty', parseFloat(tooltipObj.style.top));


        //
        // Fire the tooltip event
        //
        RG.SVG.fireCustomEvent(obj, 'ontooltip');
    };



// End module pattern
})(window, document);