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




    /**
    * The progress bar constructor
    * 
    * @param mixed conf This can either be an object that contains all of the configuration data
    *                   (the updated way of configuring the object) or it can be a string consisting of the
    *                   canvas ID
    * @param number     The minimum value (if using the older configuration style)
    * @param number     The maximum value (if using the older configuration style)
    * @param number     The represented value (if using the older configuration style)
    */
    RGraph.SemiCircularProgress = function (conf)
    {
        /**
        * Allow for object config style
        */
        if (   typeof conf === 'object'
            && typeof conf.id === 'string') {

            var parseConfObjectForOptions = true; // Set this so the config is parsed (at the end of the constructor)
        
        } else {

            var conf = {
                id: arguments[0],
                min: arguments[1],
                max: arguments[2],
                value: arguments[3]
            }
        }




        this.id                = conf.id;
        this.canvas            = document.getElementById(this.id);
        this.context           = this.canvas.getContext('2d');
        this.canvas.__object__ = this;

        this.min               = RGraph.stringsToNumbers(conf.min);
        this.max               = RGraph.stringsToNumbers(conf.max);
        this.value             = RGraph.stringsToNumbers(conf.value);
        this.type              = 'semicircularprogress';
        this.coords            = [];
        this.isRGraph          = true;
        this.currentValue      = null;
        this.uid               = RGraph.createUID();
        this.canvas.uid        = this.canvas.uid ? this.canvas.uid : RGraph.CreateUID();
        this.colorsParsed      = false;
        this.coordsText        = [];
        this.original_colors   = [];
        this.firstDraw         = true; // After the first draw this will be false


        /**
        * Compatibility with older browsers
        */
        //RGraph.OldBrowserCompat(this.context);

        this.properties =
        {
            'chart.background.color':   'rgba(0,0,0,0)',
            'chart.colors':             ['#0c0'],
            'chart.linewidth':          2,
            'chart.strokestyle':        '#666',
            'chart.gutter.left':        25,
            'chart.gutter.right':       25,
            'chart.gutter.top':         25,
            'chart.gutter.bottom':      35,
            'chart.radius':             null,
            'chart.centerx':            null,
            'chart.centery':            null,
            'chart.width':              null,
            'chart.angles.start':       Math.PI,
            'chart.angles.end':         (2 * Math.PI),
            'chart.scale.decimals':     0,
            'chart.scale.point':        '.',
            'chart.scale.thousand':     ',',
            'chart.scale.formatter':    null,
            'chart.scale.round':        false,
            'chart.shadow':             false,
            'chart.shadow.color':       'rgba(220,220,220,1)',
            'chart.shadow.blur':        2,
            'chart.shadow.offsetx':     2,
            'chart.shadow.offsety':     2,
            'chart.labels.center':      true,
            'chart.labels.center.font': null,
            'chart.labels.center.bold': false,
            'chart.labels.center.italic': false,
            'chart.labels.center.fade': false,
            'chart.labels.center.size': 40,
            'chart.labels.center.color':'black',
            'chart.labels.center.valign':'bottom',
            'chart.labels.min.color':   null,
            'chart.labels.min.font':    null,
            'chart.labels.min.bold':    false,
            'chart.labels.min.size':    null,
            'chart.labels.min.italic':  false,
            'chart.labels.min.offset.angle': 0,
            'chart.labels.min.offsetx': 0,
            'chart.labels.min.offsety': 0,
            'chart.labels.max.color':   null,
            'chart.labels.max.font':    null,
            'chart.labels.max.bold':    false,
            'chart.labels.max.size':    null,
            'chart.labels.max.italic':  false,
            'chart.labels.max.offset.angle': 0,
            'chart.labels.max.offsetx': 0,
            'chart.labels.max.offsety': 0,
            'chart.title':              '',
            'chart.title.bold':         true,
            'chart.title.italic':       false,
            'chart.title.font':         null,
            'chart.title.size':         null,
            'chart.title.color':        'black',
            'chart.text.size':          12,
            'chart.text.color':         'black',
            'chart.text.font':          'Segoe UI, Arial, Verdana, sans-serif',
            'chart.text.accessible':           true,
            'chart.text.accessible.overflow':  'visible',
            'chart.text.accessible.pointerevents': true,
            'chart.contextmenu':        null,
            'chart.units.pre':          '',
            'chart.units.post':         '',
            'chart.tooltips':           null,
            'chart.tooltips.effect':    'fade',
            'chart.tooltips.css.class': 'RGraph_tooltip',
            'chart.tooltips.highlight': true,
            'chart.tooltips.event':     'onclick',
            'chart.tooltips.coords.page':true,
            'chart.highlight.stroke':   'rgba(0,0,0,0)',
            'chart.highlight.fill':     'rgba(255,255,255,0.7)',
            'chart.annotatable':        false,
            'chart.annotate.color':     'black',
            'chart.zoom.factor':        1.5,
            'chart.zoom.fade.in':       true,
            'chart.zoom.fade.out':      true,
            'chart.zoom.hdir':          'right',
            'chart.zoom.vdir':          'down',
            'chart.zoom.frames':        25,
            'chart.zoom.delay':         16.666,
            'chart.zoom.shadow':        true,
            'chart.zoom.background':    true,
            'chart.zoom.action':        'zoom',
            'chart.resizable':              false,
            'chart.resize.handle.adjust':   [0,0],
            'chart.resize.handle.background': null,
            'chart.adjustable':         false,
            'chart.events.click':       null,
            'chart.events.mousemove':   null,
            'chart.clearto':   'rgba(0,0,0,0)'
        }

        // Check for support
        if (!this.canvas) {
            alert('[SEMICIRCULARPROGRESS] No canvas support');
            return;
        }




        /**
        * Translate half a pixel for antialiasing purposes - but only if it hasn't beeen
        * done already
        */
        if (!this.canvas.__rgraph_aa_translated__) {
            this.context.translate(0.5,0.5);
            
            this.canvas.__rgraph_aa_translated__ = true;
        }




        // Short variable names
        var RG   = RGraph,
            ca   = this.canvas,
            co   = ca.getContext('2d'),
            prop = this.properties,
            pa2  = RG.path2,
            win  = window,
            doc  = document,
            ma   = Math
        
        
        
        /**
        * "Decorate" the object with the generic effects if the effects library has been included
        */
        if (RG.Effects && typeof RG.Effects.decorate === 'function') {
            RG.Effects.decorate(this);
        }




        /**
        * A generic setter
        * 
        * @param string name  The name of the property to set or it can also be an object containing
        *                     object style configuration
        */
        this.set =
        this.Set = function (name)
        {
            var value = typeof arguments[1] === 'undefined' ? null : arguments[1];

            /**
            * the number of arguments is only one and it's an
            * object - parse it for configuration data and return.
            */
            if (arguments.length === 1 && typeof name === 'object') {
                RG.parseObjectStyleConfig(this, name);
                return this;
            }



            /**
            * This should be done first - prepend the propertyy name with "chart." if necessary
            */
            if (name.substr(0,6) != 'chart.') {
                name = 'chart.' + name;
            }
            
            
            
            // Convert uppercase letters to dot+lower case letter
            while(name.match(/([A-Z])/)) {
                name = name.replace(/([A-Z])/, '.' + RegExp.$1.toLowerCase());
            }




            prop[name.toLowerCase()] = value;
    
            return this;
        };




        /**
        * A generic getter
        * 
        * @param string name  The name of the property to get
        */
        this.get =
        this.Get = function (name)
        {
            /**
            * This should be done first - prepend the property name with "chart." if necessary
            */
            if (name.substr(0,6) != 'chart.') {
                name = 'chart.' + name;
            }

            // Convert uppercase letters to dot+lower case letter
            while(name.match(/([A-Z])/)) {
                name = name.replace(/([A-Z])/, '.' + RegExp.$1.toLowerCase());
            }
    
            return prop[name.toLowerCase()];
        };




        /**
        * Draws the progress bar
        */
        this.draw =
        this.Draw = function ()
        {
            /**
            * Fire the onbeforedraw event
            */
            RG.fireCustomEvent(this, 'onbeforedraw');



            /**
            * Parse the colors. This allows for simple gradient syntax
            */
            if (!this.colorsParsed) {
    
                this.parseColors();
    
                
                // Don't want to do this again
                this.colorsParsed = true;
            }
    
            
            /**
            * Set the current value
            */
            this.currentValue = this.value;
            
            /**
            * This is new in May 2011 and facilitates indiviual gutter settings,
            * eg chart.gutter.left
            */
            this.gutterLeft   = prop['chart.gutter.left'];
            this.gutterRight  = prop['chart.gutter.right'];
            this.gutterTop    = prop['chart.gutter.top'];
            this.gutterBottom = prop['chart.gutter.bottom'];
    
            // Figure out the width and height
            this.radius = ma.min(
                (ca.width - prop['chart.gutter.left'] - prop['chart.gutter.right']) / 2,
                ca.height - prop['chart.gutter.top'] - prop['chart.gutter.bottom']
            );
            this.centerx = ((ca.width - this.gutterLeft - this.gutterRight) / 2) + this.gutterLeft;
            this.centery = ca.height - this.gutterBottom;
            this.width   = this.radius / 3;
             
            // User specified centerx/y/radius
            if (typeof prop['chart.radius']  === 'number') this.radius = prop['chart.radius'];
            if (typeof prop['chart.centerx'] === 'number') this.centerx = prop['chart.centerx'];
            if (typeof prop['chart.centery'] === 'number') this.centery = prop['chart.centery'];
            if (typeof prop['chart.width']   === 'number') this.width   = prop['chart.width'];

            this.coords = [];



            /**
            * Stop this growing uncontrollably
            */
            this.coordsText = [];




    
            //
            // Draw the meter
            //
            this.drawMeter();
            this.drawLabels();
    
    
    
            /**
            * Setup the context menu if required
            */
            if (prop['chart.contextmenu']) {
                RG.showContext(this);
            }
    
    
            /**
            * This installs the event listeners
            */
            RG.installEventListeners(this);

    
    
            
            /**
            * This function enables resizing
            */
            if (prop['chart.resizable']) {
                RG.allowResizing(this);
            }
            
            /**
            * Instead of using RGraph.common.adjusting.js, handle them here
            */
            this.allowAdjusting();


            /**
            * Fire the onfirstdraw event
            */
            if (this.firstDraw) {
                this.firstDraw = false;
                RG.fireCustomEvent(this, 'onfirstdraw');
                this.firstDrawFunc();
            }




            /**
            * Fire the RGraph ondraw event
            */
            RG.fireCustomEvent(this, 'ondraw');
            
            return this;
        };




        /**
        * Draw the bar itself
        */
        this.drawMeter =
        this.DrawMeter = function ()
        {
            //
            // The start/end angles
            //
            var start = prop['chart.angles.start'],
                end   = prop['chart.angles.end'];

            //
            // Calculate a scale (though only two labels are shown)
            //

            this.scale2 = RG.getScale2(this, {
                'max':            this.max,
                'strict':         true,//prop['chart.scale.round'] ? false : true,
                'min':            this.min,
                'scale.thousand': prop['chart.scale.thousand'],
                'scale.point':    prop['chart.scale.point'],
                'scale.decimals': prop['chart.scale.decimals'],
                'ylabels.count':  5,
                'units.pre':      prop['chart.units.pre'],
                'units.post':     prop['chart.units.post']
            });

            // Draw the backgrundColor
            if (prop['chart.background.color'] !== 'rgba(0,0,0,0)') {
                pa2(co, 'fs % fr % % % %',
                    prop['chart.background.color'],
                    0,0,ca.width, ca.height
                );
            }


            // Draw the main semi-circle background and then lighten it by filling it again
            // in semi-transparent white
            pa2(
                co,
                'lw % b a % % % % % false a % % % % % true c s % f % sx % sy % sc % sb % f % sx 0 sy 0 sb 0 sc rgba(0,0,0,0) lw 1',
                prop['chart.linewidth'],
                this.centerx, this.centery, this.radius, start, end,
                this.centerx, this.centery, this.radius - this.width, end, start,
                prop['chart.strokestyle'],
                typeof prop['chart.colors'][1] !== 'undefined' ? prop['chart.colors'][1] : prop['chart.colors'][0],
                prop['chart.shadow.offsetx'], prop['chart.shadow.offsety'], prop['chart.shadow'] ? prop['chart.shadow.color'] : 'rgba(0,0,0,0)', prop['chart.shadow.blur'],
                typeof prop['chart.colors'][1] !== 'undefined' ? 'rgba(0,0,0,0)' : 'rgba(255,255,255,0.85)'
            );

            var angle = start + ((end - start) * ((this.value - this.scale2.min) / (this.max - this.scale2.min)));

            // Draw the meter
            pa2(
                co,
                'b a % % % % % false a % % % % % true c f %',
                this.centerx, this.centery, this.radius, start, angle,
                this.centerx, this.centery, this.radius - this.width, start + ((end - start) * ((this.value - this.scale2.min) / (this.max - this.scale2.min))), start,
                prop['chart.colors'][0]
            );

            this.coords = [[
                this.centerx,
                this.centery,
                this.radius,
                start,
                end,
                this.width,
                angle
            ]];
        };




        /**
        * The function that draws the labels
        */
        this.drawLabels =
        this.DrawLabels = function ()
        {
            var min = RG.numberFormat(
                this,
                this.scale2.min,
                prop['chart.units.pre'],
                prop['chart.units.post']
            )
            
            var max = RG.numberFormat(
                this,
                this.scale2.max,
                prop['chart.units.pre'],
                prop['chart.units.post']
            )
            











            // Determine the horizontal and vertical alignment for the text
            if (prop['chart.angles.start'] === RGraph.PI) {
                var halign = 'center';
                var valign = 'top';
            } else if (prop['chart.angles.start'] <= RGraph.PI) {
                var halign = 'left';
                var valign = 'center';
            } else if (prop['chart.angles.start'] >= RGraph.PI) {
                var halign = 'right';
                var valign = 'center';
            }

            // Get the X/Y for the min label
            // cx, cy, angle, radius
            var xy = RG.getRadiusEndPoint(
                this.centerx,
                this.centery,
                prop['chart.angles.start'] + prop['chart.labels.min.offset.angle'],
                this.radius - (this.width / 2)
            );

            // Draw the min label
            RG.text2(this, {
                font: prop['chart.labels.min.font'] || prop['chart.text.font'],
                bold: prop['chart.labels.min.bold'] || prop['chart.text.bold'],
                size: prop['chart.labels.min.size'] || prop['chart.text.size'],
                x: xy[0] + prop['chart.labels.min.offsetx'],
                y: xy[1] + prop['chart.labels.min.offsety'],
                valign: valign,
                halign: halign,
                text: min,
                color: prop['chart.labels.min.color'] || prop['chart.text.color'],
                italic: prop['chart.labels.min.italic']
            });










            // Determine the horizontal and vertical alignment for the text
            if (prop['chart.angles.end'] === RGraph.TWOPI) {
                var halign = 'center';
                var valign = 'top';
            } else if (prop['chart.angles.end'] >= RGraph.TWOPI) {
                var halign = 'right';
                var valign = 'center';
            } else if (prop['chart.angles.end'] <= RGraph.TWOPI) {
                var halign = 'left';
                var valign = 'center';
            }
            
            // Get the X/Y for the max label
            // cx, cy, angle, radius
            var xy = RG.getRadiusEndPoint(
                this.centerx,
                this.centery,
                prop['chart.angles.end'] + prop['chart.labels.max.offset.angle'],
                this.radius - (this.width / 2)
            );

            // Draw the max label
            RG.text2(this, {
                font: prop['chart.labels.max.font'] || prop['chart.text.font'],
                bold: prop['chart.labels.max.bold'] || prop['chart.text.bold'],
                size: prop['chart.labels.max.size'] || prop['chart.text.size'],
                x: xy[0] + prop['chart.labels.max.offsetx'],
                y: xy[1] + prop['chart.labels.max.offsety'],
                valign: valign,
                halign: halign,
                text: max,
                color: prop['chart.labels.max.color'] || prop['chart.text.color'],
                italic: prop['chart.labels.max.italic']
            });














            // Draw the big label in the center
            if (prop['chart.labels.center']) {
                var ret = RG.text2(this, {
                    font: prop['chart.labels.center.font'] || prop['chart.text.font'],
                    size: prop['chart.labels.center.size'] || 50,
                    bold: prop['chart.labels.center.bold'],
                    italic: prop['chart.labels.center.italic'],
                    x: this.centerx,
                    y: this.centery,
                    valign: prop['chart.labels.center.valign'],
                    halign: 'center',
                    text: RG.numberFormat(
                        this,
                        this.value.toFixed(prop['chart.scale.decimals']),
                        prop['chart.units.pre'],
                        prop['chart.units.post']
                    ),
                    color: prop['chart.labels.center.color'] || prop['chart.text.color']
                });
                
                // Allows the center label to fade in
                if (prop['chart.labels.center.fade'] && ret.node) {
                    ret.node.style.opacity = 0;
    
                    var delay = 25,
                        incr  = 0.1;
    
                    for (var i=0; i<10; ++i) {
                        (function (index)
                        {
                            setTimeout(function  ()
                            {
                                ret.node.style.opacity = incr * index;
                            }, delay * (index + 1));
                        })(i);
                    }
                }
            }
            
            // Draw the title
            RG.drawTitle(
                this,
                prop['chart.title'],
                this.gutterTop,
                null,
                prop['chart.title.size']
            );
        };




        /**
        * Returns the focused bar
        * 
        * @param event e The event object
        */
        this.getShape = function (e)
        {
            var mouseXY = RG.getMouseXY(e),
                mouseX  = mouseXY[0],
                mouseY  = mouseXY[1]

            // Draw the meter here but don't stroke or fill it
            // so that it can be tested with isPointInPath()
            pa2(
                co,
                'b a % % % % % false a % % % % % true',
                this.coords[0][0], this.coords[0][1], this.coords[0][2], this.coords[0][3], this.coords[0][6],
                this.coords[0][0], this.coords[0][1], this.coords[0][2] - this.coords[0][5], this.coords[0][6], this.coords[0][3]
            );



            if (co.isPointInPath(mouseX, mouseY)) {

                return {
                    object: this,              0: this,
                         x: this.coords[0][0], 1: this.coords[0][0],
                         y: this.coords[0][1], 2: this.coords[0][1],
                    radius: this.coords[0][2], 3: this.coords[0][2],
                     width: this.coords[0][5], 4: this.coords[0][5],
                     start: this.coords[0][3], 5: this.coords[0][3],
                       end: this.coords[0][6], 6: this.coords[0][6],
                     index: 0,
                   tooltip: !RG.isNull(prop['chart.tooltips']) ? prop['chart.tooltips'][0] : null
                };
            }
        };




        /**
        * This function returns the value that the mouse is positioned at, regardless of
        * the actual indicated value.
        * 
        * @param object e The event object
        */
        this.getValue = function (e)
        {
            var mouseXY = RG.getMouseXY(e),
                mouseX  = mouseXY[0],
                mouseY  = mouseXY[1],
                angle   = RG.getAngleByXY(
                    this.centerx,
                    this.centery,
                    mouseX,
                    mouseY
                );
                
                if (
                    angle &&
                    mouseX >= this.centerx
                    && mouseY > this.centery
                    ) {
                    
                    angle += RGraph.TWOPI;
                }

            if (angle < prop['chart.angles.start'] && mouseX > this.centerx) { angle = prop['chart.angles.end']; }
            if (angle < prop['chart.angles.start']) { angle = prop['chart.angles.start']; }

            var value = (((angle - prop['chart.angles.start']) / (prop['chart.angles.end'] - prop['chart.angles.start'])) * (this.max - this.min)) + this.min;

            value = ma.max(value, this.min);
            value = ma.min(value, this.max);

            return value;
        };




        /**
        * Each object type has its own Highlight() function which highlights the appropriate shape
        * 
        * @param object shape The shape to highlight
        */
        this.highlight =
        this.Highlight = function (shape)
        {
            if (typeof prop['chart.highlight.style'] === 'function') {
                (prop['chart.highlight.style'])(shape);
            } else {
                pa2(co, 'lw 5 b a % % % % % false a % % % % % true c s % f % lw 1',
                    shape.x, shape.y, shape.radius, shape.start, shape.end,
                    shape.x, shape.y, shape.radius - shape.width, shape.end, shape.start,
                    prop['chart.highlight.stroke'],
                    prop['chart.highlight.fill']
                );
            }
        };




        /**
        * The getObjectByXY() worker method. Don't call this call:
        * 
        * RGraph.ObjectRegistry.getObjectByXY(e)
        * 
        * @param object e The event object
        */
        this.getObjectByXY = function (e)
        {
            var mouseXY = RG.getMouseXY(e);

            // Draw a Path so that the coords can be tested
            // (but don't stroke/fill it
            pa2(co,
                'b a % % % % % false',
                this.centerx,
                this.centery,
                this.radius,
                prop['chart.angles.start'],
                prop['chart.angles.end']
            );

            pa2(co,
                'a % % % % % true',
                this.centerx,
                this.centery,
                this.radius - this.width,
                prop['chart.angles.end'],
                prop['chart.angles.start']
            );

            return co.isPointInPath(mouseXY[0], mouseXY[1]) ? this : null;
        };




        /**
        * This function allows the VProgress to be  adjustable.
        * UPDATE: Not any more
        */
        this.allowAdjusting =
        this.AllowAdjusting = function () {};




        /**
        * This method handles the adjusting calculation for when the mouse is moved
        * 
        * @param object e The event object
        */
        this.adjusting_mousemove =
        this.Adjusting_mousemove = function (e)
        {
            /**
            * Handle adjusting for the HProgress
            */
            if (prop['chart.adjustable'] && RG.Registry.Get('chart.adjusting') && RG.Registry.Get('chart.adjusting').uid == this.uid) {

                var value   = this.getValue(e);
                
                if (typeof value === 'number') {
    
                    // Fire the onadjust event
                    RG.fireCustomEvent(this, 'onadjust');

                    this.value = Number(value.toFixed(prop['chart.scale.decimals']));
                    RG.redrawCanvas(this.canvas);
                }
            }
        };




        /**
        * This function positions a tooltip when it is displayed
        * 
        * @param obj object    The chart object
        * @param int x         The X coordinate specified for the tooltip
        * @param int y         The Y coordinate specified for the tooltip
        * @param objec tooltip The tooltips DIV element
        *
        this.positionTooltip = function (obj, x, y, tooltip, idx)
        {
            var coordX     = obj.coords[tooltip.__index__][0],
                coordY     = obj.coords[tooltip.__index__][1],
                coordW     = obj.coords[tooltip.__index__][2],
                coordH     = obj.coords[tooltip.__index__][3],
                canvasXY   = RG.getCanvasXY(obj.canvas),
                mouseXY    = RG.getMouseXY(window.event),
                gutterLeft = obj.gutterLeft,
                gutterTop  = obj.gutterTop,
                width      = tooltip.offsetWidth,
                height     = tooltip.offsetHeight
            /*
            // Set the top position
            tooltip.style.left = 0;
            tooltip.style.top  = window.event.pageY - height - 5 + 'px';
            
            // By default any overflow is hidden
            tooltip.style.overflow = '';
            
            // Reposition the tooltip if at the edges:
            
            // LEFT edge
            if (canvasXY[0] + mouseXY[0] - (width / 2) < 0) {
                tooltip.style.left = canvasXY[0] + mouseXY[0]  - (width * 0.1) + 'px';
    
            // RIGHT edge
            } else if (canvasXY[0] + mouseXY[0]  + (width / 2) > doc.body.offsetWidth) {
                tooltip.style.left = canvasXY[0] + mouseXY[0]  - (width * 0.9) + 'px';
    
            // Default positioning - CENTERED
            } else {
                tooltip.style.left = canvasXY[0] + mouseXY[0]  - (width / 2) + 'px';
            }
        };*/




        /**
        * This function returns the appropriate angle (in radians) for the given
        * Y value
        * 
        * @param  int value The Y value you want the angle for
        * @returm int       The angle
        */
        this.getAngle = function (value)
        {
            if (value > this.max || value < this.min) {
                return null;
            }

            var angle = (value / this.max) * (prop['chart.angles.end'] - prop['chart.angles.start'])
                angle += prop['chart.angles.start'];

            return angle;
        };




        /**
        * This returns true/false as to whether the cursor is over the chart area.
        * The cursor does not necessarily have to be over the bar itself.
        */
        this.overChartArea = function  (e)
        {
            var mouseXY = RGraph.getMouseXY(e),
                mouseX  = mouseXY[0],
                mouseY  = mouseXY[1]

            // Draw the background to the Progress but don't stroke or fill it
            // so that it can be tested with isPointInPath()
            pa2(
                co,
                'b a % % % % % false a % % % % % true',
                this.coords[0][0], this.coords[0][1], this.coords[0][2], prop['chart.angles.start'], prop['chart.angles.end'],
                this.coords[0][0], this.coords[0][1], this.coords[0][2] - this.coords[0][5], prop['chart.angles.end'], prop['chart.angles.start']
            );

            return co.isPointInPath(mouseX, mouseY);
        };




        /**
        * 
        */
        this.parseColors = function ()
        {
            // Save the original colors so that they can be restored when the canvas is reset
            if (this.original_colors.length === 0) {
                this.original_colors['chart.colors'] = RG.arrayClone(prop['chart.colors']);
            }

            prop['chart.colors'][0] = this.parseSingleColorForGradient(prop['chart.colors'][0]);
            prop['chart.colors'][1] = this.parseSingleColorForGradient(prop['chart.colors'][1]);
            
            prop['chart.strokestyle']      = this.parseSingleColorForGradient(prop['chart.strokestyle']);
            prop['chart.background.color'] = this.parseSingleColorForGradient(prop['chart.background.color']);
        };




        /**
        * Use this function to reset the object to the post-constructor state. Eg reset colors if
        * need be etc
        */
        this.reset = function ()
        {
        };




        /**
        * This parses a single color value
        */
        this.parseSingleColorForGradient = function (color)
        {
            if (!color || typeof color != 'string') {
                return color;
            }
    
            if (color.match(/^gradient\((.*)\)$/i)) {
                var parts = RegExp.$1.split(':');
    
                // Create the gradient
                var grad = co.createLinearGradient(prop['chart.gutter.left'],0,ca.width - prop['chart.gutter.right'],0);
    
                var diff = 1 / (parts.length - 1);
    
                grad.addColorStop(0, RG.trim(parts[0]));
    
                for (var j=1,len=parts.length; j<len; ++j) {
                    grad.addColorStop(j * diff, RG.trim(parts[j]));
                }
                
                return grad ? grad : color;
            }
    
            return grad ? grad : color;
        };




        /**
        * Using a function to add events makes it easier to facilitate method chaining
        * 
        * @param string   type The type of even to add
        * @param function func 
        */
        this.on = function (type, func)
        {
            if (type.substr(0,2) !== 'on') {
                type = 'on' + type;
            }
            
            if (typeof this[type] !== 'function') {
                this[type] = func;
            } else {
                RG.addCustomEventListener(this, type, func);
            }
    
            return this;
        };




        /**
        * Used in chaining. Runs a function there and then - not waiting for
        * the events to fire (eg the onbeforedraw event)
        * 
        * @param function func The function to execute
        */
        this.exec = function (func)
        {
            func(this);
            
            return this;
        };




        /**
        * This function runs once only
        * (put at the end of the file (before any effects))
        */
        this.firstDrawFunc = function ()
        {
        };




        /**
        * HProgress Grow effect (which is also the VPogress Grow effect)
        * 
        * @param object obj The chart object
        */
        this.grow = function ()
        {
            var obj           = this,
                initial_value = this.currentValue,
                opt           = arguments[0] || {},
                numFrames     = opt.frames || 30,
                frame         = 0,
                callback      = arguments[1] || function () {},
                diff          = this.value - Number(this.currentValue),
                increment     = diff  / numFrames
            
            //if (prop['chart.labels.center']) {
            //    var labelsCenter = true;
            //    this.set('labelsCenter', false);
            //}



            function iterator ()
            {
                frame++;
    
                if (frame <= numFrames) {
    
                    obj.value = initial_value + (increment * frame);
    
                    RG.clear(ca);
                    RG.redrawCanvas(ca);
                    
                    RG.Effects.updateCanvas(iterator);
                } else {
                    //if (labelsCenter) {
                    //    obj.set('labelsCenter', true);
                    //    RG.redrawCanvas(ca);
                    //}
                    callback();
                }
            }
            
            iterator();
            
            return this;
        };



        /**
        * The chart is now always registered
        */
        RG.Register(this);




        /**
        * This is the 'end' of the constructor so if the first argument
        * contains configuration data - handle that.
        */
        if (parseConfObjectForOptions) {
            RG.parseObjectStyleConfig(this, conf.options);
        }
    };