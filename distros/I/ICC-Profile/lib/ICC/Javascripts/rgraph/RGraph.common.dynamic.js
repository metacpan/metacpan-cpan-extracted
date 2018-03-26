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

    /**
    * Initialise the various objects
    */
    RGraph = window.RGraph || {isRGraph: true};

// Module pattern
(function (win, doc, undefined)
{
    var RG = RGraph,
        ua = navigator.userAgent,
        ma = Math;




    /**
    * This is the window click event listener. It redraws all canvas tags on the page.
    */
    RG.installWindowMousedownListener =
    RG.InstallWindowMousedownListener = function (obj)
    {
        if (!RG.window_mousedown_event_listener) {

            RG.window_mousedown_event_listener = function (e)
            {
                /**
                * For firefox add the window.event object
                */
                if (navigator.userAgent.indexOf('Firefox') >= 0) win.event = e;
                
                e = RG.fixEventObject(e);
    

                if (RG.HideTooltip && RG.Registry.Get('chart.tooltip')) {
                    RG.clear(RG.Registry.Get('chart.tooltip').__canvas__);
                    RG.redraw();
                    RG.hideTooltip();
                }
            };
            win.addEventListener('mousedown', RG.window_mousedown_event_listener, false);
        }
    };




    /**
    * This is the window click event listener. It redraws all canvas tags on the page.
    */
    RG.installWindowMouseupListener =
    RG.InstallWindowMouseupListener = function (obj)
    {
        if (!RG.window_mouseup_event_listener) {
            RG.window_mouseup_event_listener = function (e)
            {
                /**
                * For firefox add the window.event object
                */
                if (navigator.userAgent.indexOf('Firefox') >= 0) win.event = e;
                
                e = RG.fixEventObject(e);
    
    
                /**
                * Stop any annotating that may be going on
                */
                if (RG.annotating_window_onmouseup) {
                    RG.annotating_window_onmouseup(e);
                    return;
                }
    
                /**
                * End adjusting
                */
                if (RG.Registry.Get('chart.adjusting') || RG.Registry.Get('chart.adjusting.gantt')) {
                
                    var obj = RG.Registry.Get('chart.adjusting');
                
                    // If it's a line chart update the data_arr variable
                    if (obj && obj.type === 'line') {
                        obj.data_arr = RG.arrayLinearize(obj.data);
                    }

                    RG.fireCustomEvent(RG.Registry.Get('chart.adjusting'), 'onadjustend');
                }
    
                RG.Registry.set('chart.adjusting', null);
                RG.Registry.set('chart.adjusting.shape', null);
                RG.Registry.set('chart.adjusting.gantt', null);
    
    
                // ==============================================
                // Finally, redraw the chart
                // ==============================================

                var tags = document.getElementsByTagName('canvas');
                for (var i=0; i<tags.length; ++i) {
                    if (tags[i].__object__ && tags[i].__object__.isRGraph) {
                        if (!tags[i].__object__.get('chart.annotatable')) {
                            if (!tags[i].__rgraph_trace_cover__ && !noredraw) {
                                RG.clear(tags[i]);
                            } else {
                                var noredraw = true;
                            }
                        }
                    }
                }
    
                if (!noredraw) {
                    RG.redraw();
                }
            };
            win.addEventListener('mouseup', RG.window_mouseup_event_listener, false);
        }
    };




    /**
    * This is the canvas mouseup event listener. It installs the mouseup event for the
    * canvas. The mouseup event then checks the relevant object.
    * 
    * @param object obj The chart object
    * 
    * RGraph.window_mouseup_event_listener
    */
    RG.installCanvasMouseupListener =
    RG.InstallCanvasMouseupListener = function (obj)
    {
        if (!obj.canvas.rgraph_mouseup_event_listener) {
            obj.canvas.rgraph_mouseup_event_listener = function (e)
            {
                /**
                * For firefox add the window.event object
                */
                if (navigator.userAgent.indexOf('Firefox') >= 0) window.event = e;
    
                e = RG.fixEventObject(e);
    
    
                // *************************************************************************
                // Tooltips
                // *************************************************************************
    
    
                // This causes things at the edge of the chart area - eg line chart hotspots - not to fire because the
                // cursor is out of the chart area
                var objects = RG.ObjectRegistry.getObjectsByXY(e);
                //var objects = RG.ObjectRegistry.getObjectsByCanvasID(e.target.id);


                if (objects) {
                    for (var i=0,len=objects.length; i<len; i+=1) {

                        var obj = objects[i],
                            id  = objects[i].id;

    
                        // =========================================================================
                        // The drawing API text object supports chart.link
                        // ========================================================================
                        var link = obj.Get('link');
                        
                        if (obj.type == 'drawing.text' && typeof link === 'string') {

                            var link_target  = obj.get('link.target');
                            var link_options = obj.get('link.options');

                            window.open(link, link_target ? link_target : null, link_options);
                        }

    
                        // ========================================================================
                        // Tooltips
                        // ========================================================================
    

                        if (!RG.isNull(obj) && RG.tooltip) {
    
                            var shape = obj.getShape(e);

                            if (shape && shape['tooltip']) {
    
                                var text = shape['tooltip'];
    
                                if (text) {

                                    var type = shape['object'].type;
    
                                    RG.clear(obj.canvas);
                                    RG.redraw();
                                    RG.Registry.set('chart.tooltip.shape', shape);
                                    
                                    // Note that tooltips are positioned at the pointer
                                    // now; and thats done within the .tooltip() function
                                    RG.tooltip(obj, text, 0, 0, shape['index'], e);

                                    obj.highlight(shape);

                                    // Add the shape that triggered the tooltip
                                    if (RG.Registry.get('chart.tooltip')) {
                                        
                                        RG.Registry.get('chart.tooltip').__shape__ = shape;
    
                                        RG.evaluateCursor(e);
                                    }
    
                                    e.cancelBubble = true;
                                    e.stopPropagation();
                                    return false;
                                }
                            }
                        }
    
    
    
    
    
                        // =========================================================================
                        // Adjusting
                        // ========================================================================
        
        
        
                        if (RG.Registry.get('chart.adjusting') || RG.Registry.get('chart.adjusting.gantt')) {

                        //var obj = RG.Registry.get('chart.adjusting');
                    
                        // If it's a line chart update the data_arr variable
                        if (obj && obj.type === 'line') {
                            obj.data_arr = RG.arrayLinearize(obj.data);
                        }

                            RG.fireCustomEvent(RG.Registry.get('chart.adjusting'), 'onadjustend');
                        }
        
                        RG.Registry.set('chart.adjusting', null);
                        RG.Registry.set('chart.adjusting.shape', null);
                        RG.Registry.set('chart.adjusting.gantt', null);
    
                        /**
                        * If the mouse pointer is over a "front" chart this prevents charts behind it
                        * from firing their events.
                        */
                        if (shape || (obj.overChartArea && obj.overChartArea(e)) ) {
                            break;
                        }
                    }
                }
            };
            obj.canvas.addEventListener('mouseup', obj.canvas.rgraph_mouseup_event_listener, false);
        }
    };




    /**
    * This is the canvas mousemove event listener.
    * 
    * @param object obj The chart object
    */
    RG.installCanvasMousemoveListener =
    RG.InstallCanvasMousemoveListener = function (obj)
    {
        if (!obj.canvas.rgraph_mousemove_event_listener) {
            obj.canvas.rgraph_mousemove_event_listener = function (e)
            {

                /**
                * For firefox add the window.event object
                */
                if (navigator.userAgent.indexOf('Firefox') >= 0) window.event = e;
                e = RG.fixEventObject(e);

    
    
    
                /**
                * Go through all the objects and check them to see if anything needs doing
                */
                var objects = RG.OR.getObjectsByXY(e);

                // Necessary to track which objects have had the mouseover
                // triggered on them
                var uids = [];

                if (objects && objects.length > 0) {

                    for (var i=0,len=objects.length; i<len; i+=1) {

                        var obj = objects[i];
                        var id  = obj.id;


                        // Record the uid
                        uids[obj.uid] = true;


                        if (!obj.getShape) {
                            continue;
                        }
    

                        var shape = obj.getShape(e);
                        
                        // Fire the onmouseout event if necessary
                        if (
                            (!shape && typeof obj.__mouseover_shape_index__ === 'number') ||
                            (shape && typeof obj.__mouseover_shape_index__ === 'number' && shape.index !== obj.__mouseover_shape_index__)
                            ) {
                            
                            RG.fireCustomEvent(obj, 'onmouseout');
                        }







                        //
                        // If the mouse is over a key element add the details
                        // of it to the Registry
                        //
                        if (obj.coords && obj.coords.key && obj.coords.key.length) {
                            
                            var mouseXY = RG.getMouseXY(e);
    
                            for (var i=0,overkey=false; i<obj.coords.key.length; ++i) {
                                        
                                if (
                                       mouseXY[0] >= obj.coords.key[i][0]
                                    && mouseXY[0] <= (obj.coords.key[i][0] + obj.coords.key[i][2])
                                    && mouseXY[1] >= obj.coords.key[i][1]
                                    && mouseXY[1] <= (obj.coords.key[i][1] + obj.coords.key[i][3])
                                   ) {
    
                                    RG.Registry.set('key-element', obj.coords.key[i]);
                                    overkey = true;
                                }

                                if (!overkey) {
                                    RG.Registry.set('key-element', null);
                                }
                            }
                        }




                        // ================================================================================================ //
                        // This facilitates the chart.events.mousemove option
                        // ================================================================================================ //
                        
                        var func = obj.get('chart.events.mousemove');
    
                        if (!func && typeof obj.onmousemove == 'function') {
                            var func = obj.onmousemove;
                        }

                        /**
                        * 
                        */
                        if (shape) {
                            var index = shape['object'].type == 'scatter' ? shape['index_adjusted'] : shape['index'];
                            if (typeof(obj['$' + index]) == 'object' && typeof(obj['$' + index].onmousemove) == 'function') {
                                var func2 = obj['$' + index].onmousemove;
                            }
                        }

                        /**
                        * This bit saves the current pointer style if there isn't one already saved
                        */
                        if (shape && (typeof(func) == 'function' || typeof(func2) == 'function' || typeof obj.Get('link') === 'string')) {

                            if (obj.Get('chart.events.mousemove.revertto') == null) {
                                obj.Set('chart.events.mousemove.revertto', e.target.style.cursor);
                            }

                            if (typeof(func)  == 'function')  RGraph.custom_events_mousemove_pointer = func(e, shape);
                            if (typeof(func2) == 'function') RGraph.custom_events_mousemove_pointer  = RGraph.custom_events_mousemove_pointer || func2(e, shape);

                            // Go through the RGraph.events array looking for more
                            // event listeners
                            if (   typeof RG.events === 'object'
                                && typeof RG.events[obj.uid] === 'object') {
                                
                                for (i in RG.events[obj.uid]) {
                                
                                    if (   typeof i === 'string'
                                        && typeof RG.events[obj.uid][i] === 'object'
                                        && RG.events[obj.uid][i][1] === 'onmousemove'
                                        && typeof RG.events[obj.uid][i][2] === 'function') {
                                        
                                        (RG.events[obj.uid][i][2])(obj);
                                    }
                                }
                            }
                            //return;
    
                        } else if (typeof(obj.Get('chart.events.mousemove.revertto')) == 'string') {
            
                            RG.cursor.push('default');
                            obj.Set('chart.events.mousemove.revertto', null);
                        }





















                        // ======================================================
                        // This bit of code facilitates the onmouseover event
                        // ======================================================



                        var func = obj.properties['chart.events.mouseover'];

                        if (!func && typeof obj.onmouseover === 'function') {
                            func = obj.onmouseover;
                        }


                        // Allow for individually index functions to be specified
                        if (shape) {
                        
                            var index = shape['object'].type == 'scatter' ? shape['index_adjusted'] : shape['index'];

                            if (typeof(obj['$' + index]) == 'object' && typeof(obj['$' + index].onmouseover) == 'function') {
                                var func2 = obj['$' + index].onmouseover;
                            }
                        } else {

                            obj.__mouseover_shape_index__ = null;
                            RG.__mouseover_objects__      = [];
                        }

                        if (typeof RG.__mouseover_objects__ === 'undefined') {
                            RG.__mouseover_objects__ = [];
                        }


                        if (shape) {
                            if ((obj.__mouseover_shape_index__ === shape.index) === false) {

                                obj.__mouseover_shape_index__ = shape.index;
                                RG.__mouseover_objects__.push(obj);

                                if (func) func(e, shape);
                                if (func2) func2(e, shape);

                                // Go through the RGraph.events array looking for more
                                // event listeners
                                if (   typeof RG.events === 'object'
                                    && typeof RG.events[obj.uid] === 'object') {
                                    
                                    for (i in RG.events[obj.uid]) {
                                    
                                        if (   typeof i === 'string'
                                            && typeof RG.events[obj.uid][i] === 'object'
                                            && RG.events[obj.uid][i][1] === 'onmouseover'
                                            && typeof RG.events[obj.uid][i][2] === 'function') {
                                            
                                            (RG.events[obj.uid][i][2])(obj);
                                        }
                                    }
                                }
                            }
                        } else {
                            obj.__mouseover_shape_index__ = null;
                            RG.__mouseover_objects__      = [];
                        }






















    
                        // ================================================================================================ //
                        // Tooltips
                        // ================================================================================================ //
                        var current_tooltip = RG.Registry.get('chart.tooltip');
                        var tooltips        = obj.get('chart.tooltips');
                        var tooltips_event  = obj.Get('chart.tooltips.event');


                        if (   shape
                            && (tooltips && tooltips[shape['index']] || shape['tooltip'])
                            && tooltips_event.indexOf('mousemove')  !== -1
                            && (   RG.isNull(current_tooltip) // Is there a tooltip being shown?
                                || obj.uid != current_tooltip.__object__.uid // Same object?
                                || (current_tooltip.__index__ != shape['index']) // Same tooltip index?
                                || (typeof shape['dataset'] === 'number' && shape['dataset'] != current_tooltip.__shape__['dataset'])
                                )
                           ) {

                            RG.clear(obj.canvas);
                            RG.hideTooltip();
                            RG.redraw();
                            obj.canvas.rgraph_mouseup_event_listener(e);
    
                            return;
                        }
            
            
                        // ================================================================================================ //
                        // Adjusting
                        // ================================================================================================ //
            

                        if (obj && obj.get('chart.adjustable')) {
                            obj.Adjusting_mousemove(e);
                        }
                    
    
                        /**
                        * This facilitates breaking out of the loop when a shape has been found - 
                        * ie the cursor is over a shape an upper chart
                        */
                        if (shape || (obj.overChartArea && obj.overChartArea(e) )) {
                            break;
                        }
                    }
                    
                    //
                    // For all objects that are NOT mouseover'ed, reset the
                    // mouseover flag back to null
                    //
                    var objects = RG.OR.getObjectsByCanvasID(e.target.id);

                    for (var i=0; i<objects.length; ++i) {
                        if (!uids[objects[i].uid]) {
                            objects[i].__mouseover_shape_index__ = null;
                        }
                    }

                } else {

                    // Reset the mouseover flag on all of this canvas tags objects
                    var objects = RG.OR.getObjectsByCanvasID(e.target.id);

                    for (var i=0; i<objects.length; i++) {

                        if (typeof objects[i].__mouseover_shape_index__ === 'number') {
                            RG.fireCustomEvent(objects[i], 'onmouseout');
                        }

                        objects[i].__mouseover_shape_index__ = null;
                    }

                    RG.__mouseover_objects__ = [];
                }







                // ================================================================================================ //
                // Crosshairs
                // ================================================================================================ //
    

                if (e.target && e.target.__object__ && e.target.__object__.get('chart.crosshairs')) {
                    RG.drawCrosshairs(e, e.target.__object__);
                }
            
            
                // ================================================================================================ //
                // Interactive key No LONGER REQUIRED
                // ================================================================================================ //
    
    
                //if (typeof InteractiveKey_line_mousemove == 'function') InteractiveKey_line_mousemove(e);
                //if (typeof InteractiveKey_pie_mousemove == 'function') InteractiveKey_pie_mousemove(e);
    
    
                // ================================================================================================ //
                // Annotating
                // ================================================================================================ //
    
    
                if (e.target.__object__ && e.target.__object__.get('chart.annotatable') && RG.annotating_canvas_onmousemove) {
                    RG.annotating_canvas_onmousemove(e);
                }
    
    
    
                /**
                * Determine the pointer
                */
                RG.evaluateCursor(e);
            };
            obj.canvas.addEventListener('mousemove', obj.canvas.rgraph_mousemove_event_listener, false);
        }
    };




    /**
    * This is the canvas mousedown event listener.
    * 
    * @param object obj The chart object
    */
    RG.installCanvasMousedownListener =
    RG.InstallCanvasMousedownListener = function (obj)
    {
        if (!obj.canvas.rgraph_mousedown_event_listener) {
            obj.canvas.rgraph_mousedown_event_listener = function (e)
            {
                /**
                * For firefox add the window.event object
                */
                if (navigator.userAgent.indexOf('Firefox') >= 0) window.event = e;
                
                e = RG.fixEventObject(e);

    
                /**
                * Annotating
                */
                if (e.target.__object__ && e.target.__object__.get('chart.annotatable') && RG.annotating_canvas_onmousedown) {
                    RG.annotating_canvas_onmousedown(e);
                    return;
                }
    
                var obj = RG.ObjectRegistry.getObjectByXY(e);

                if (obj) {

                    var id = obj.id;
                    


                    /*************************************************************
                    * Handle adjusting for all object types
                    *************************************************************/
                    if (obj && obj.isRGraph && obj.get('chart.adjustable')) {

                        /**
                        * Check the cursor is in the correct area
                        */
                        var obj = RG.OR.getObjectByXY(e);
    
                        if (obj && obj.isRGraph) {
                        
                            // If applicable, get the appropriate shape and store it in the registry
                            switch (obj.type) {
                                case 'bar':   var shape = obj.getShapeByX(e); break;
                                case 'gantt':
                                    
                                    var shape = obj.getShape(e);
                                    var data = typeof shape.subindex === 'number' ?  obj.data[shape.index][shape.subindex] : obj.data[shape.index];

                                    if (shape) {

                                        var mouseXY = RG.getMouseXY(e);

                                        RG.Registry.set('chart.adjusting.gantt', {
                                            index: shape.index,
                                            subindex: shape.subindex,
                                            object: obj,
                                            mousex: mouseXY[0],
                                            mousey: mouseXY[1],
                                            event: data,
                                            event_start: data[0],
                                            event_duration: data[1],
                                            mode: (mouseXY[0] > (shape['x'] + shape['width'] - 5) ? 'resize' : 'move'),
                                            shape: shape
                                        });
                                    }
                                    break;
                                case 'line':  var shape = obj.getShape(e); break;
                                case 'hbar':  var shape = obj.getShapeByY(e); break;
                                default:      var shape = null;
                            }
                            
                            //
                            // Added 30/9/2016
                            // Now check the index in the chart.adjusting.limitto property
                            // If that property is an object and the appropriate index is
                            // truthy then allow adjusting, otherwise don't.
                            //
                            if (
                                   RG.isNull(obj.properties['chart.adjustable.only'])
                                || typeof obj.properties['chart.adjustable.only'] === 'undefined'
                                ||
                                   (
                                       RG.isArray(obj.properties['chart.adjustable.only'])
                                    && obj.isAdjustable
                                    && obj.isAdjustable(shape)
                                   )
                               ) {

                                RG.Registry.set('chart.adjusting.shape', shape);
    
        
                                // Fire the onadjustbegin event
                                RG.fireCustomEvent(obj, 'onadjustbegin');
        
                                RG.Registry.set('chart.adjusting', obj);
            
        
                                // Liberally redraw the canvas
                                RG.clear(obj.canvas);
                                RG.redraw();
            
                                // Call the mousemove event listener so that the canvas
                                // is adjusted even though the mouse isn't moved
                                obj.canvas.rgraph_mousemove_event_listener(e);
                            }
                        }
                    }
    
    
                    RG.clear(obj.canvas);
                    RG.redraw();
                }
            };
            obj.canvas.addEventListener('mousedown', obj.canvas.rgraph_mousedown_event_listener, false);
        }
    };




    /**
    * This is the canvas click event listener. Used by the pseudo event listener
    * 
    * @param object obj The chart object
    */
    RG.installCanvasClickListener =
    RG.InstallCanvasClickListener = function (obj)
    {
        if (!obj.canvas.rgraph_click_event_listener) {
            obj.canvas.rgraph_click_event_listener = function (e)
            {
                /**
                * For firefox add the window.event object
                */
                if (navigator.userAgent.indexOf('Firefox') >= 0) window.event = e;
                
                e = RG.fixEventObject(e);
    
                var objects = RG.ObjectRegistry.getObjectsByXY(e);

                for (var i=0,len=objects.length; i<len; i+=1) {

                    var obj   = objects[i];
                    var id    = obj.id;
                    var shape = obj.getShape(e);

                    /**
                    * This bit saves the current pointer style if there isn't one already saved
                    */
                    var func = obj.get('chart.events.click');
                    
                    if (!func && typeof(obj.onclick) == 'function') {
                        func = obj.onclick;
                    }

                    if (shape && typeof func == 'function') {

                        func(e, shape);

                        // Go through the RGraph.events array looking for more
                        // event listeners

                        if (   typeof RG.events === 'object'
                            && typeof RG.events[obj.uid] === 'object') {

                            for (i in RG.events[obj.uid]) {

                                if (   typeof i === 'string'
                                    && typeof RG.events[obj.uid][i] === 'object'
                                    && RG.events[obj.uid][i][1] === 'onclick'
                                    && typeof RG.events[obj.uid][i][2] === 'function') {
                                    
                                    (RG.events[obj.uid][i][2])(obj);
                                }
                            }
                        }
                        
                        /**
                        * If objects are layered on top of each other this return
                        * stops objects underneath from firing once the "top"
                        * objects user event has fired
                        */
                        return;
                    }
                    
                    
                    
                    //
                    // Handle the key click event
                    //
                    var key = RG.Registry.get('key-element');
                    if (key) {
                        RG.fireCustomEvent(obj, 'onkeyclick');
                    }





                    /**
                    * The property takes priority over this.
                    */
                    if (shape) {
    
                        var index = shape['object'].type == 'scatter' ? shape['index_adjusted'] : shape['index'];
        
                        if (typeof(index) == 'number' && obj['$' + index]) {
                            
                            var func = obj['$' + index].onclick;

                            if (typeof(func) == 'function') {
                                
                                func(e, shape);
                                
                                /**
                                * If objects are layered on top of each other this return
                                * stops objects underneath from firing once the "top"
                                * objects user event has fired
                                */
                                return;
                            }
                        }
                    }
                    
                    /**
                    * This facilitates breaking out of the loop when a shape has been found - 
                    * ie the cursor is over a shape an upper chart
                    */
                    if (shape || (obj.overChartArea && obj.overChartArea(e)) ) {
                        break;
                    }
                }
            };
            obj.canvas.addEventListener('click', obj.canvas.rgraph_click_event_listener, false);
        }
    };




    /**
    * This function evaluates the various cursor settings and if there's one for pointer, changes it to that
    */
    RG.evaluateCursor =
    RG.EvaluateCursor = function (e)
    {
        var obj     = null;
        var mouseXY = RG.getMouseXY(e);
        var mouseX  = mouseXY[0];
        var mouseY  = mouseXY[1];
        var canvas  = e.target;

        /**
        * Tooltips cause the mouse pointer to change
        */
        var objects = RG.OR.getObjectsByCanvasID(canvas.id);
        
        for (var i=0,len=objects.length; i<len; i+=1) {
            if ((objects[i].getShape && objects[i].getShape(e)) || (objects[i].overChartArea && objects[i].overChartArea(e))) {
                var obj = objects[i];
                var id  = obj.id;
            }
        }

        if (!RG.isNull(obj)) {
            if (obj.getShape && obj.getShape(e)) {

                var shape = obj.getShape(e);

                if (obj.get('chart.tooltips')) {

                    var text = RG.parseTooltipText(obj.get('chart.tooltips'), shape['index']);
                    
                    if (!text && shape['object'].type == 'scatter' && shape['index_adjusted']) {
                        text = RG.parseTooltipText(obj.get('chart.tooltips'), shape['index_adjusted']);
                    }

                    /**
                    * This essentially makes front charts "hide" the back charts
                    */
                    if (text) {
                        var pointer = true;
                    }
                }
            }

            /**
            * Now go through the key coords and see if it's over that.
            */
            if (!RG.isNull(obj) && obj.Get('chart.key.interactive')) {
                for (var j=0; j<obj.coords.key.length; ++j) {
                    if (mouseX > obj.coords.key[j][0] && mouseX < (obj.coords.key[j][0] + obj.coords.key[j][2]) && mouseY > obj.coords.key[j][1] && mouseY < (obj.coords.key[j][1] + obj.coords.key[j][3])) {
                        var pointer = true;
                    }
                }
            }
        }

        /**
        * It can be specified in the user mousemove event - remember it can now
        * be specified in THREE ways
        */
        if (RGraph.custom_events_mousemove_pointer) {
            var pointer = true;
            RGraph.custom_events_mousemove_pointer = false;
        }
        /*

            
            var index = shape['object'].type == 'scatter' ? shape['index_adjusted'] : shape['index'];
            if (!RG.isNull(obj['$' + index]) && typeof(obj['$' + index].onmousemove) == 'function') {
                var str = (obj['$' + index].onmousemove).toString();
                if (str.match(/pointer/) && str.match(/cursor/) && str.match(/style/)) { 
                    var pointer = true;
                }
            }
        }
        */

        /**
        * Is the chart resizable? Go through all the objects again
        */
        var objects = RG.OR.objects.byCanvasID;

        for (var i=0,len=objects.length; i<len; i+=1) {
            if (objects[i] && objects[i][1].Get('chart.resizable')) {
                var resizable = true;
            }
        }

        if (resizable && mouseX > (e.target.width - 32) && mouseY > (e.target.height - 16)) {
            pointer = true;
        }


        if (pointer) {
            e.target.style.cursor = 'pointer';
        } else if (e.target.style.cursor == 'pointer') {
            e.target.style.cursor = 'default';
        } else {
            e.target.style.cursor = null;
        }

        

        // =========================================================================
        // Resize cursor - check mouseis in bottom left corner and if it is change it
        // =========================================================================


        if (resizable && mouseX >= (e.target.width - 15) && mouseY >= (e.target.height - 15)) {
            e.target.style.cursor = 'move';
        
        } else if (e.target.style.cursor === 'move') {
            e.target.style.cursor = 'default';
        }


        // =========================================================================
        // Interactive key
        // =========================================================================



        if (typeof mouse_over_key == 'boolean' && mouse_over_key) {
            e.target.style.cursor = 'pointer';
        }

        
        // =========================================================================
        // Gantt chart adjusting
        // =========================================================================

        //if (obj && obj.type == 'gantt' && obj.get('chart.adjustable')) {
        //    if (obj.getShape && obj.getShape(e)) {
        //        e.target.style.cursor = 'ew-resize';
        //    } else {
        //        e.target.style.cursor = 'default';
        //    }
        //} else if (!obj || !obj.type) {
        //    e.target.style.cursor = cursor;
        //}

        
        // =========================================================================
        // Line chart adjusting
        // =========================================================================


        if (obj && obj.type == 'line' && obj.get('chart.adjustable')) {
            if (obj.getShape) {

                var shape = obj.getShape(e);

                if (shape && obj.isAdjustable(shape)) {
                    e.target.style.cursor = 'ns-resize';
                }
            } else {
                e.target.style.cursor = 'default';
            }
        }

        
        // =========================================================================
        // Annotatable
        // =========================================================================


        if (e.target.__object__ && e.target.__object__.get('chart.annotatable')) {
            e.target.style.cursor = 'crosshair';
        }

        
        // =========================================================================
        // Drawing API link
        // =========================================================================


        if (obj && obj.type === 'drawing.text' && shape && typeof obj.get('link') === 'string') {
            e.target.style.cursor = 'pointer';
        }
    };




    /**
    * This function handles the tooltip text being a string, function
    * 
    * @param mixed tooltip This could be a string or a function. If it's a function it's called and
    *                       the return value is used as the tooltip text
    * @param numbr idx The index of the tooltip.
    */
    RG.parseTooltipText = function (tooltips, idx)
    {
        // No tooltips
        if (!tooltips) {
            return null;
        }

        // Get the tooltip text
        if (typeof tooltips == 'function') {
            var text = tooltips(idx);

        // A single tooltip. Only supported by the Scatter chart
        } else if (typeof tooltips == 'string') {
            var text = tooltips;

        } else if (typeof tooltips == 'object' && typeof tooltips[idx] == 'function') {
            var text = tooltips[idx](idx);

        } else if (typeof tooltips[idx] == 'string' && tooltips[idx]) {
            var text = tooltips[idx];

        } else {
            var text = '';
        }

        if (text == 'undefined') {
            text = '';
        } else if (text == 'null') {
            text = '';
        }

        // Conditional in case the tooltip file isn't included
        return RG.getTooltipTextFromDIV ? RG.getTooltipTextFromDIV(text) : text;
    };




    /**
    * Draw crosshairs if enabled
    * 
    * @param object obj The graph object (from which we can get the context and canvas as required)
    */
    RG.drawCrosshairs =
    RG.DrawCrosshairs = function (e, obj)
    {
        var e            = RG.fixEventObject(e),
            width        = obj.canvas.width,
            height       = obj.canvas.height,
            mouseXY      = RG.getMouseXY(e),
            x            = mouseXY[0],
            y            = mouseXY[1],
            gutterLeft   = obj.gutterLeft,
            gutterRight  = obj.gutterRight,
            gutterTop    = obj.gutterTop,
            gutterBottom = obj.gutterBottom,
            Mathround    = Math.round,
            prop         = obj.properties,
            co           = obj.context,
            ca           = obj.canvas

        RG.redrawCanvas(ca);

        if (   x >= gutterLeft
            && y >= gutterTop
            && x <= (width - gutterRight)
            && y <= (height - gutterBottom)
           ) {

            var linewidth = prop['chart.crosshairs.linewidth'] ? prop['chart.crosshairs.linewidth'] : 1;
            co.lineWidth = linewidth ? linewidth : 1;

            co.beginPath();
            co.strokeStyle = prop['chart.crosshairs.color'];





            /**
            * The chart.crosshairs.snap option
            */
            if (prop['chart.crosshairs.snap']) {
            
                // Linear search for the closest point
                var point = null;
                var dist  = null;
                var len   = null;
                
                if (obj.type == 'line') {
            
                    for (var i=0; i<obj.coords.length; ++i) {
                    
                        var length = RG.getHypLength(obj.coords[i][0], obj.coords[i][1], x, y);
            
                        // Check the mouse X coordinate
                        if (typeof dist != 'number' || length < dist) {
                            var point = i;
                            var dist = length;
                        }
                    }
                
                    x = obj.coords[point][0];
                    y = obj.coords[point][1];
                    
                    // Get the dataset
                    for (var dataset=0; dataset<obj.coords2.length; ++dataset) {
                        for (var point=0; point<obj.coords2[dataset].length; ++point) {
                            if (obj.coords2[dataset][point][0] == x && obj.coords2[dataset][point][1] == y) {
                                ca.__crosshairs_snap_dataset__ = dataset;
                                ca.__crosshairs_snap_point__   = point;
                            }
                        }
                    }

                } else {
            
                    for (var i=0; i<obj.coords.length; ++i) {
                        for (var j=0; j<obj.coords[i].length; ++j) {
                            
                            // Check the mouse X coordinate
                            var len = RG.getHypLength(obj.coords[i][j][0], obj.coords[i][j][1], x, y);
            
                            if (typeof(dist) != 'number' || len < dist) {
            
                                var dataset = i;
                                var point   = j;
                                var dist   = len;
                            }
                        }
            
                    }
                    ca.__crosshairs_snap_dataset__ = dataset;
                    ca.__crosshairs_snap_point__   = point;

            
                    x = obj.coords[dataset][point][0];
                    y = obj.coords[dataset][point][1];
                }
            }






            // Draw a top vertical line
            if (prop['chart.crosshairs.vline']) {
                co.moveTo(Mathround(x), Mathround(gutterTop));
                co.lineTo(Mathround(x), Mathround(height - gutterBottom));
            }

            // Draw a horizontal line
            if (prop['chart.crosshairs.hline']) {
                co.moveTo(Mathround(gutterLeft), Mathround(y));
                co.lineTo(Mathround(width - gutterRight), Mathround(y));
            }

            co.stroke();
            
            
            /**
            * Need to show the coords?
            */
            if (obj.type == 'scatter' && prop['chart.crosshairs.coords']) {

                var xCoord = (((x - gutterLeft) / (width - gutterLeft - gutterRight)) * (prop['chart.xmax'] - prop['chart.xmin'])) + prop['chart.xmin'];
                    xCoord = xCoord.toFixed(prop['chart.scale.decimals']);
                var yCoord = obj.max - (((y - prop['chart.gutter.top']) / (height - gutterTop - gutterBottom)) * obj.max);

                if (obj.type == 'scatter' && obj.properties['chart.xaxispos'] == 'center') {
                    yCoord = (yCoord - (obj.max / 2)) * 2;
                }

                yCoord = yCoord.toFixed(prop['chart.scale.decimals']);

                var div      = RG.Registry.get('chart.coordinates.coords.div');
                var mouseXY  = RG.getMouseXY(e);
                var canvasXY = RG.getCanvasXY(ca);
                
                if (!div) {
                    var div = document.createElement('DIV');
                        div.__object__               = obj;
                        div.style.position           = 'absolute';
                        div.style.backgroundColor    = 'white';
                        div.style.border             = '1px solid black';
                        div.style.fontFamily         = 'Arial, Verdana, sans-serif';
                        div.style.fontSize           = '10pt'
                        div.style.padding            = '2px';
                        div.style.opacity            = 1;
                        div.style.WebkitBorderRadius = '3px';
                        div.style.borderRadius       = '3px';
                        div.style.MozBorderRadius    = '3px';
                    document.body.appendChild(div);
                    
                    RG.Registry.set('chart.coordinates.coords.div', div);
                }

                // Convert the X/Y pixel coords to correspond to the scale
                div.style.opacity = 1;
                div.style.display = 'inline';

                if (!prop['chart.crosshairs.coords.fixed']) {
                    div.style.left = ma.max(2, (e.pageX - div.offsetWidth - 3)) + 'px';
                    div.style.top = ma.max(2, (e.pageY - div.offsetHeight - 3))  + 'px';
                } else {
                    div.style.left = canvasXY[0] + gutterLeft + 3 + 'px';
                    div.style.top  = canvasXY[1] + gutterTop + 3 + 'px';
                }

                // Use the formatter functions if defined. This allows the user to format them as they wish
                if (typeof prop['chart.crosshairs.coords.formatter.x'] === 'function') {
                    xCoord = (prop['chart.crosshairs.coords.formatter.x'])({object: obj, value: parseInt(xCoord)});
                }
                if (typeof prop['chart.crosshairs.coords.formatter.y'] === 'function') {
                    yCoord = (prop['chart.crosshairs.coords.formatter.y'])({object: obj, value: parseInt(yCoord)});
                }

                div.innerHTML = '<span style="color: #666">' + prop['chart.crosshairs.coords.labels.x'] + ':</span> ' + xCoord + '<br><span style="color: #666">' + prop['chart.crosshairs.coords.labels.y'] + ':</span> ' + yCoord;

                obj.canvas.addEventListener('mouseout', RG.hideCrosshairCoords, false);

                ca.__crosshairs_labels__ = div;
                ca.__crosshairs_x__ = xCoord;
                ca.__crosshairs_y__ = yCoord;

            } else if (prop['chart.crosshairs.coords']) {
                alert('[RGRAPH] Showing crosshair coordinates is only supported on the Scatter chart');
            }

            /**
            * Fire the oncrosshairs custom event
            */
            RG.fireCustomEvent(obj, 'oncrosshairs');

        } else {
            RG.hideCrosshairCoords();
        }
    };




    //
    // Adds a mousemove event listener that highlights a segment based on th
    // mousemove event. Used in the Rose and the RScatter charts
    //
    //@param int segments The number of segments to allow
    //
    RG.allowSegmentHighlight = function (opt)
    {
        var obj    = opt.object,
            count  = opt.count,
            fill   = opt.fill,
            stroke = opt.stroke

        if (!RG.segmentHighlightFunction) {

            RG.segmentHighlightFunction = function (e)
            {

                var mouseXY = RG.getMouseXY(e);
                var angle   = RG.getAngleByXY(obj.centerx, obj.centery, mouseXY[0], mouseXY[1]);

                angle += RG.HALFPI;

                if (angle > RG.TWOPI) {
                    angle -= RG.TWOPI;
                }

                RG.redraw();
        
                var start = 0;
                var end   = 0;
                var a     = (ma.PI * 2) / count;
                
                //
                // Radius
                //
                var r = obj.radius;


                (function ()
                {
                    for (i=0; i<count; i+=1) {
                        if (angle < (a * (i + 1))) {
                            start = i * a;
                            end   = (i + 1) * a;
                            
                            return;
                        }
                    }
                })();
                
                start -= RG.HALFPI;
                end   -= RG.HALFPI;
                

                RG.path2(
                    obj.context,
                    'b m % % a % % % % % false c s % f %',
                    obj.centerx, obj.centery,
                    obj.centerx,obj.centery,r,start,end,
                    stroke,
                    fill
                );
        
            };
            obj.canvas.addEventListener('mousemove', RG.segmentHighlightFunction, false);
        }
    }




// End module pattern
})(window, document);