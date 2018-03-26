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
    * The bar chart constructor
    * 
    * @param object canvas The canvas object
    * @param array  data   The chart data
    */
    RGraph.Waterfall = function (conf)
    {
        /**
        * Allow for object config style
        */
        if (   typeof conf === 'object'
            && typeof conf.data === 'object'
            && typeof conf.id === 'string') {

            var parseConfObjectForOptions = true; // Set this so the config is parsed (at the end of the constructor)
        
        } else {
        
            var conf = {
                id: conf,
                data: arguments[1]
            };
        }




        this.id                = conf.id;
        this.canvas            = document.getElementById(this.id);
        this.context           = this.canvas.getContext ? this.canvas.getContext("2d") : null;
        this.canvas.__object__ = this;
        this.type              = 'waterfall';
        this.max               = 0;
        this.data              = conf.data;
        this.isRGraph          = true;
        this.coords            = [];
        this.uid               = RGraph.CreateUID();
        this.canvas.uid        = this.canvas.uid ? this.canvas.uid : RGraph.CreateUID();
        this.colorsParsed      = false;
        this.coordsText        = [];
        this.original_colors   = [];
        this.firstDraw         = true; // After the first draw this will be false


        // Various config
        this.properties =
        {
            'chart.background.barcolor1':   'rgba(0,0,0,0)',
            'chart.background.barcolor2':   'rgba(0,0,0,0)',
            'chart.background.grid':        true,
            'chart.background.grid.color':  '#ddd',
            'chart.background.grid.width':  1,
            'chart.background.grid.hsize':  20,
            'chart.background.grid.vsize':  20,
            'chart.background.grid.vlines': true,
            'chart.background.grid.hlines': true,
            'chart.background.grid.border': true,
            'chart.background.grid.autofit':true,
            'chart.background.grid.autofit.align': true,
            'chart.background.grid.autofit.numhlines': 5,
            'chart.background.grid.autofit.numvlines': 20,
            'chart.background.image':       null,
            'chart.background.hbars':       null,
            'chart.linewidth':              1,
            'chart.axis.linewidth':         1,
            'chart.xaxispos':               'bottom',
            'chart.numxticks':              null,
            'chart.numyticks':              10,
            'chart.hmargin':                5,
            'chart.strokestyle':            '#666',
            'chart.axis.color':             'black',
            'chart.gutter.left':            25,
            'chart.gutter.right':           25,
            'chart.gutter.top':             25,
            'chart.gutter.bottom':          25,
            'chart.labels':                 [],
            'chart.labels.bold':            false,
            'chart.labels.offsetx':         0,
            'chart.labels.offsety':         0,
            'chart.ylabels.offsetx':        0,
            'chart.ylabels.offsety':        0,
            'chart.ylabels':                true,
            'chart.text.color':             'black',
            'chart.text.size':              12,
            'chart.text.angle':             0,
            'chart.text.font':              'Segoe UI, Arial, Verdana, sans-serif',
            'chart.text.accessible':               true,
            'chart.text.accessible.overflow':      'visible',
            'chart.text.accessible.pointerevents': true,
            'chart.ymax':                   null,
            'chart.title':                  '',
            'chart.title.color':            'black',
            'chart.title.background':       null,
            'chart.title.hpos':             null,
            'chart.title.vpos':             null,
            'chart.title.bold':             true,
            'chart.title.font':             null,
            'chart.title.xaxis':            '',
            'chart.title.yaxis':            '',
            'chart.title.yaxis.bold':       true,
            'chart.title.yaxis.size':       null,
            'chart.title.yaxis.font':       null,
            'chart.title.yaxis.color':      null,
            'chart.title.xaxis.pos':        null,
            'chart.title.yaxis.pos':        null,
            'chart.title.yaxis.align':      'left',
            'chart.title.xaxis.bold':       true,
            'chart.title.xaxis.size':       null,
            'chart.title.xaxis.font':       null,
            'chart.title.xaxis.color':      null,
            'chart.title.yaxis.x':          null,
            'chart.title.yaxis.y':          null,
            'chart.title.xaxis.x':          null,
            'chart.title.xaxis.y':          null,
            'chart.title.x':                null,
            'chart.title.y':                null,
            'chart.title.halign':           null,
            'chart.title.valign':           null,
            'chart.colors':                 ['green','red','blue'],
            'chart.colors.sequential':      false,
            'chart.shadow':                 false,
            'chart.shadow.color':           '#666',
            'chart.shadow.offsetx':         3,
            'chart.shadow.offsety':         3,
            'chart.shadow.blur':            3,
            'chart.tooltips':               null,
            'chart.tooltips.effect':        'fade',
            'chart.tooltips.css.class':     'RGraph_tooltip',
            'chart.tooltips.event':         'onclick',
            'chart.tooltips.highlight':     true,
            'chart.tooltips.override':     null,
            'chart.highlight.stroke':       'rgba(0,0,0,0)',
            'chart.highlight.fill':         'rgba(255,255,255,0.7)',
            'chart.contextmenu':            null,
            'chart.units.pre':              '',
            'chart.units.post':             '',
            'chart.scale.decimals':         0,
            'chart.scale.point':            '.',
            'chart.scale.thousand':         ',',
            'chart.scale.zerostart':        true,
            //'chart.scale.formatter':        null,
            'chart.crosshairs':             false,
            'chart.crosshairs.color':       '#333',
            'chart.crosshairs.hline':       true,
            'chart.crosshairs.vline':       true,
            'chart.annotatable':            false,
            'chart.annotate.color':         'black',
            'chart.zoom.factor':            1.5,
            'chart.zoom.fade.in':           true,
            'chart.zoom.fade.out':          true,
            'chart.zoom.hdir':              'right',
            'chart.zoom.vdir':              'down',
            'chart.zoom.frames':            25,
            'chart.zoom.delay':             16.666,
            'chart.zoom.shadow':            true,
            'chart.zoom.background':        true,
            'chart.resizable':              false,
            'chart.resize.handle.background': null,
            'chart.noaxes':                 false,
            'chart.noxaxis':                false,
            'chart.noyaxis':                false,
            'chart.axis.color':             'black',
            'chart.total':                  true,
            'chart.multiplier.x':           1,
            'chart.multiplier.w':           1,
            'chart.events.click':           null,
            'chart.events.mousemove':       null,
            'chart.ylabels.count':          5,
            'chart.ymin':                   0,
            'chart.clearto':                'rgba(0,0,0,0)',
            'chart.key':                    null,
            'chart.key.background':         'white',
            'chart.key.position':           'graph',
            'chart.key.halign':             'right',
            'chart.key.shadow':             false,
            'chart.key.shadow.color':       '#666',
            'chart.key.shadow.blur':        3,
            'chart.key.shadow.offsetx':     2,
            'chart.key.shadow.offsety':     2,
            'chart.key.position.gutter.boxed': false,
            'chart.key.position.x':         null,
            'chart.key.position.y':         null,
            'chart.key.color.shape':        'square',
            'chart.key.rounded':            true,
            'chart.key.linewidth':          1,
            'chart.key.colors':             null,
            'chart.key.interactive':        false,
            'chart.key.interactive.highlight.chart.stroke': '#000',
            'chart.key.interactive.highlight.chart.fill':   'rgba(255,255,255,0.7)',
            'chart.key.interactive.highlight.label':        'rgba(255,0,0,0.2)',
            'chart.key.text.color':         'black',
        }

        // Check for support
        if (!this.canvas) {
            alert('[WATERFALL] No canvas support');
            return;
        }
        
        /**
        * Create the $ objects
        * 
        * 2/5/016: Now also use this loop to go through the dat conerting
        * strings to floats
        */
        for (var i=0,len=this.data.length; i<=len; ++i) {
            
            // Create the object for adding event listeners
            this['$' + i] = {}
            
            // Ensure that the data point is numeric
            if (typeof this.data[i] === 'string') {
                this.data[i] = parseFloat(this.data[i]);
            }
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
        * A setter
        * 
        * @param name  string The name of the property to set
        * @param value mixed  The value of the property
        */
        this.set =
        this.Set = function (name, value)
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



            if (name == 'chart.total' && prop['chart.numxticks'] == null) {
                prop['chart.numxticks'] = this.data.length;
            }



            prop[name.toLowerCase()] = value;
    
            return this;
        };




        /**
        * A getter
        * 
        * @param name  string The name of the property to get
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
        * The function you call to draw the bar chart
        */
        this.draw =
        this.Draw = function ()
        {
            /**
            * Fire the onbeforedraw event
            */
            RGraph.fireCustomEvent(this, 'onbeforedraw');
            
    
            /**
            * Parse the colors. This allows for simple gradient syntax
            */
            if (!this.colorsParsed) {
                this.parseColors();
                
                // Don't want to do this again
                this.colorsParsed = true;
            }
    
            
            /**
            * Draw the background image
            */
            RGraph.DrawBackgroundImage(this);
            
            /**
            * This is new in May 2011 and facilitates indiviual gutter settings,
            * eg chart.gutter.left
            */
            this.gutterLeft   = prop['chart.gutter.left'];
            this.gutterRight  = prop['chart.gutter.right'];
            this.gutterTop    = prop['chart.gutter.top'];
            this.gutterBottom = prop['chart.gutter.bottom'];

            /**
            * Stop the coords array from growing uncontrollably
            */
            this.coords = [];



            /**
            * Stop this growing uncontrollably
            */
            this.coordsText = [];




            /**
            * This gets used a lot
            */
            this.centery = ((ca.height - this.gutterTop - this.gutterBottom) / 2) + this.gutterTop;

            /**
            * Work out a few things. They need to be here because they depend on things you can change after you instantiate the object
            */
            this.max            = 0;
            this.grapharea      = ca.height - this.gutterTop - this.gutterBottom;
            this.graphwidth     = ca.width - this.gutterLeft - this.gutterRight;
            this.halfTextHeight = prop['chart.text.size'] / 2;
    
    
            /**
            * Work out the maximum value
            */
            this.max     = this.getMax(this.data);

            var decimals = prop['chart.scale.decimals'];

            this.scale2 = RG.getScale2(this, {
                max:typeof(prop['chart.ymax']) == 'number' ? prop['chart.ymax'] : this.max,
                min:prop['chart.ymin'],
                strict: typeof(prop['chart.ymax']) === 'number' ? true : false,
                'scale.decimals':Number(decimals),
                'scale.point':prop['chart.scale.point'],
                'scale.thousand':prop['chart.scale.thousand'],
                'scale.round':prop['chart.scale.round'],
                'units.pre':prop['chart.units.pre'],
                'units.post':prop['chart.units.post'],
                'ylabels.count':prop['chart.ylabels.count']
            });

            this.max = this.scale2.max;
            this.min = this.scale2.min;
    
            // Draw the background hbars
            RG.drawBars(this)

            // Progressively Draw the chart
            RG.Background.draw(this);
    
            this.DrawAxes();
            this.Drawbars();
            this.DrawLabels();
            
            /**
            * If the X axis is at the bottom AND ymin is 0 - draw the it
            * again so that it appears "on top" of the bars
            */
            if (   prop['chart.xaxispos'] === 'bottom'
                && prop['chart.noaxes'] === false
                && prop['chart.noxaxis'] === false
                && prop['chart.ymin'] === 0) {

                co.strokeStyle = prop['chart.axis.color'];
                co.strokeRect(
                    prop['chart.gutter.left'],
                    ca.height - prop['chart.gutter.bottom'],
                    ca.width - this.gutterLeft - this.gutterRight,
                    0
                );
            }
    
            /**
            * Setup the context menu if required
            */
            if (prop['chart.contextmenu']) {
                RG.ShowContext(this);
            }
    
            
            /**
            * This function enables resizing
            */
            if (prop['chart.resizable']) {
                RG.AllowResizing(this);
            }
    
    
            /**
            * This installs the event listeners
            */
            RG.InstallEventListeners(this);
            
            
            // Draw a key if necessary
            if (prop['chart.key'] && prop['chart.key'].length) {
                RG.DrawKey(this, prop['chart.key'], prop['chart.colors']);
            }


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
            RG.FireCustomEvent(this, 'ondraw');
            
            return this;
        };




        /**
        * Draws the charts axes
        */
        this.drawAxes =
        this.DrawAxes = function ()
        {
            if (prop['chart.noaxes']) {
                return;
            }
    
            co.beginPath();
            co.strokeStyle = prop['chart.axis.color'];
            co.lineWidth   = prop['chart.axis.linewidth'] + 0.001;
    
            // Draw the Y axis
            if (prop['chart.noyaxis'] == false) {
                co.moveTo(ma.round(this.gutterLeft), this.gutterTop);
                co.lineTo(ma.round(this.gutterLeft), ca.height - this.gutterBottom);
            }

            // Draw the X axis
            if (prop['chart.noxaxis'] == false) {
                // Center X axis
                if (prop['chart.xaxispos'] == 'center') {
                    co.moveTo(this.gutterLeft, ma.round( ((ca.height - this.gutterTop - this.gutterBottom) / 2) + this.gutterTop));
                    co.lineTo(ca.width - this.gutterRight, ma.round( ((ca.height - this.gutterTop - this.gutterBottom) / 2) + this.gutterTop));
                } else {
                
                    var y = ma.floor(this.getYCoord(0));

                    co.moveTo(this.gutterLeft, y);
                    co.lineTo(ca.width - this.gutterRight, y);
                }
            }

            var numYTicks = prop['chart.numyticks'];
    
            // Draw the Y tickmarks
            if (   prop['chart.noyaxis'] === false
                && prop['chart.numyticks'] > 0
               ) {
    
                var yTickGap = (ca.height - this.gutterTop - this.gutterBottom) / numYTicks;
        
                for (y=this.gutterTop; y < (ca.height - this.gutterBottom); y += yTickGap) {
                    if (prop['chart.xaxispos'] == 'bottom' || (y != ((ca.height - this.gutterTop - this.gutterBottom) / 2) + this.gutterTop)) {
                        co.moveTo(this.gutterLeft, ma.round( y));
                        co.lineTo(this.gutterLeft - 3, ma.round( y));
                    }
                }

                /**
                * If the X axis is not being shown, draw an extra tick
                */
                if (   prop['chart.noxaxis']
                    || prop['chart.xaxispos'] == 'center'
                    || prop['chart.ymin'] !== 0
                   ) {
                    co.moveTo(this.gutterLeft - 3, Math.round(ca.height - this.gutterBottom));
                    co.lineTo(this.gutterLeft, Math.round(ca.height - this.gutterBottom));
                }
            }


            // Draw the X tickmarks
            if (prop['chart.numxticks'] == null) {
                prop['chart.numxticks'] = this.data.length + (prop['chart.total'] ? 1 : 0)
            }
    
            if (prop['chart.noxaxis'] == false && prop['chart.numxticks'] > 0) {
    
                xTickGap = (ca.width - this.gutterLeft - this.gutterRight ) / prop['chart.numxticks'];
                
                if (prop['chart.xaxispos'] == 'center') {
                    yStart   = ((ca.height - this.gutterBottom - this.gutterTop) / 2) + this.gutterTop - 3;
                    yEnd     = ((ca.height - this.gutterBottom - this.gutterTop) / 2) + this.gutterTop + 3;
                } else {
                    yStart   = this.getYCoord(0) - (this.scale2.min < 0 ? 3 : 0);
                    yEnd     = this.getYCoord(0) + 3;
                }
        
                for (x=this.gutterLeft + xTickGap; x<=ca.width - this.gutterRight + 1; x+=xTickGap) {
                    co.moveTo(ma.round(x), yStart);
                    co.lineTo(ma.round(x), yEnd);
                }
                
                if (prop['chart.noyaxis']) {
                    co.moveTo(ma.round( this.gutterLeft), yStart);
                    co.lineTo(ma.round( this.gutterLeft), yEnd);
                }
            }
    
            /**
            * If the Y axis is not being shown, draw an extra tick
            */
            if (prop['chart.noyaxis'] && prop['chart.noxaxis'] == false) {
                co.moveTo(ma.round(this.gutterLeft), this.getYCoord(0));
                co.lineTo(ma.round(this.gutterLeft), this.getYCoord(0));
            }
    
            co.stroke();
        };




        /**
        * Draws the labels for the graph
        */
        this.drawLabels =
        this.DrawLabels = function ()
        {
            var context    = co,
                numYLabels = 5, // TODO Make this configurable
                interval   = this.grapharea / numYLabels,
                font       = prop['chart.text.font'],
                size       = prop['chart.text.size'],
                color      = prop['chart.text.color'],
                units_pre  = prop['chart.units.pre'],
                units_post = prop['chart.units.post'],
                offsetx    = prop['chart.ylabels.offsetx'],
                offsety    = prop['chart.ylabels.offsety'];
            
            co.beginPath();
            co.fillStyle = color;
    
            /**
            * First, draw the Y labels
            */
            if (prop['chart.ylabels']) {
                if (prop['chart.xaxispos'] == 'center') {
    
                    var halfInterval = interval / 2;
                    var halfWay      = ((ca.height - this.gutterTop - this.gutterBottom) / 2) + this.gutterTop;

                    for (var i=0,len=this.scale2.labels.length; i<len; ++i) {
                        RG.text2(this, {
                            font:font,
                            size:size,
                            x:this.gutterLeft - 5 + offsetx,
                            y: this.gutterTop + (((this.grapharea/2) / len) * i) + offsety,
                            text:this.scale2.labels[len - i - 1],
                            valign:'center',
                            halign:'right',
                            tag: 'scale'
                        });
                        
                        RG.text2(this, {
                            font:font,
                            size:size,
                            x:this.gutterLeft - 5 + offsetx,
                            y: halfWay + (((this.grapharea/2) / len) * (i + 1)) + offsety,
                            text:this.scale2.labels[i],
                            valign:'center',
                            halign:'right',
                            tag: 'scale'
                        });
                    }
                    
                    // Draw zero if required
                    if (prop['chart.scale.zerostart']) {
                        RG.text2(co, {
                            x: this.gutterLeft - 5 + offsetx,
                            y: halfWay,
                            text: '0',
                            font: font,
                            size: size,
                            valign: 'center',
                            halign: 'right',
                            tag: 'scale'
                        });
                    }

                } else {

                    for (var i=0,len=this.scale2.values.length; i<len; ++i) {

                        var y = this.getYCoord(this.scale2.values[i]) + offsety;

                        RG.text2(this, {
                            font:font,
                            size:size,
                            x:this.gutterLeft - 5 + offsetx,
                            y: y,
                            text:this.scale2.labels[i],
                            valign:'center',
                            halign:'right',
                            tag: 'scale'
                        });
                    }


                    // Draw zero if required
                    if (prop['chart.scale.zerostart'] || prop['chart.ymin'] !== 0) {

                        RG.text2(co, {
                            x:      this.gutterLeft - 5 + offsetx,
                            y:      this.getYCoord(prop['chart.ymin'] || 0),
                            text:   RG.numberFormat(this, String(Number(prop['chart.ymin'] || 0).toFixed(prop['chart.ymin'] === 0 ? 0 : prop['chart.scale.decimals'])), prop['chart.units.pre'], prop['chart.units.post']),
                            font:   font,
                            size:   size,
                            valign: 'center',
                            halign: 'right',
                            tag:    'scale'
                        });
                    }
                }
            }
    
    
    
            /**
            * Now, draw the X labels
            */
            if (prop['chart.labels'].length > 0) {
            
                // Recalculate the interval for the X labels
                interval = (ca.width - this.gutterLeft - this.gutterRight) / prop['chart.labels'].length;
                
                var halign = 'center',
                    valign = 'top',
                    angle  = prop['chart.text.angle'];
                
                if (angle) {
                    halign = 'right';
                    angle *= -1;
                }
    
                var labels      = prop['chart.labels'],
                    labelsColor = prop['chart.labels.color'],
                    bold        = prop['chart.labels.bold'],
                    offsetx     = prop['chart.labels.offsetx'],
                    offsety     = prop['chart.labels.offsety']
    
                for (var i=0,len=labels.length; i<len; i+=1) {
                    RG.text2(this, {
                        color:  labelsColor,
                        font:   font,
                        size:   size,
                        bold:   bold,
                        x:      this.gutterLeft + (i * interval) + (interval / 2) + offsetx,
                        y:      ca.height - this.gutterBottom + this.halfTextHeight + offsety,
                        text:   labels[i],
                        valign: valign,
                        halign: halign,
                        angle:  angle,
                        tag:    'labels'
                    });
                }
            }
            
            co.stroke();
            co.fill();
        };




        /**
        * Draws the bars on to the chart
        */
        this.drawbars =
        this.Drawbars = function ()
        {
            var context      = co,
                canvas       = ca,
                hmargin      = prop['chart.hmargin'],
                runningTotal = 0;
    
            co.lineWidth = prop['chart.linewidth'] + 0.001;

            for (var i=0,len=this.data.length,seq=0; i<len; ++i,++seq) {
                
                co.beginPath();
                    
                    co.strokeStyle = prop['chart.strokestyle'];

                    var x = ma.round( this.gutterLeft + hmargin + (((this.graphwidth / (this.data.length + (prop['chart.total'] ? 1 : 0))) * i) * prop['chart.multiplier.x']));
                    
                    // Must be before the y coord calculation
                    var h  = this.getYCoord(0) - this.getYCoord(ma.abs(this.data[i]));

                    
                    
                    // Work out the Y coordinate
                    if (i === 0) {
                        y = this.getYCoord(0) - h;
                    } else {
                        y = this.getYCoord(runningTotal) - h;
                    }
                    y = ma.round(y);
                    




                    var w = ((ca.width - this.gutterLeft - this.gutterRight) / (this.data.length + (prop['chart.total'] ? 1 : 0 )) ) - (2 * prop['chart.hmargin']);
                        w = w * prop['chart.multiplier.w'];


                    // Adjust the coords for negative values
                    if (this.data[i] < 0) {
                        y += h;
                    }

                    // Color
                    co.fillStyle = this.data[i] >= 0 ? prop['chart.colors'][0] : prop['chart.colors'][1];
                    
                    // Allow for sequential colors
                    if (prop['chart.colors.sequential']) {
                        co.fillStyle = prop['chart.colors'][seq];
                    }

                    
                    if (prop['chart.shadow']) {
                        RG.setShadow(this, prop['chart.shadow.color'], prop['chart.shadow.offsetx'], prop['chart.shadow.offsety'], prop['chart.shadow.blur']);
                    } else {
                        RG.noShadow(this);
                    }

                    co.rect(x, ma.floor(y), w, ma.floor(h));

                    this.coords.push([x, y, w, h]);
                    


                    runningTotal += this.data[i];

                co.stroke();
                co.fill();
            }
                
            // Store the total
            this.total = runningTotal;

            if (prop['chart.total']) {

                // This is the height of the final bar
                h = this.getYCoord(0) - this.getYCoord(ma.abs(runningTotal));

                /**
                * Set the Y (ie the start point) value
                */
                if (prop['chart.xaxispos'] == 'center') {
                    y = runningTotal > 0 ? this.getYCoord(0) - h : this.getYCoord(0);
                } else {
                    if (runningTotal > 0) {
                        y = this.getYCoord(0) - h;
                    } else {
                        y = this.getYCoord(0);
                    }
                }
            
                // This is the X position of the final bar
                x = x + (prop['chart.hmargin'] * 2) + w;
            
            
                // Final color
                co.fillStyle = prop['chart.colors'][2];
                
                // Allow for sequential colors
                if (prop['chart.colors.sequential']) {
                    co.fillStyle = prop['chart.colors'][seq]
                }
            
                pa2(co, 'b r % % % % s % f %',
                    x, y, w, h,
                    co.strokeStyle,
                    co.fillStyle
                );

                // This is set so that the next iteration of the loop will be able to
                // access THIS iterations coordinates
                var previousCoords = [x, y, w, ma.abs(h)];

                // Add the coordinates to the coords array (the previousCooords array, at
                // this point, is actually THIS iterations coords 
                this.coords.push(previousCoords);
            }





            // Turn off the shadow
            RG.noShadow(this);






            /**
            * This draws the connecting lines
            */
            co.lineWidth   = 1;
            co.strokeStyle = '#666';
            
            co.beginPath();

            for (var i=1,len=this.coords.length; i<len; i+=1) {

                var prev     = this.coords[i - 1],
                    curr     = this.coords[i],
                    prevData = this.data[i-1]
                
                // CANNOT be a part of the var chain above
                var y = (prevData > 0 ? prev[1] : prev[1] + prev[3]);


                co.moveTo(prev[0] + prev[2], y);
                co.lineTo(curr[0],(prevData > 0 ? prev[1] : prev[1] + prev[3]));

            }
            
            co.stroke();
        };




        /**
        * Not used by the class during creating the graph, but is used by event handlers
        * to get the coordinates (if any) of the selected bar
        * 
        * @param object e The event object
        */
        this.getShape =
        this.getBar = function (e)
        {
            /**
            * Loop through the bars determining if the mouse is over a bar
            */
            for (var i=0,len=this.coords.length; i<len; i++) {
    
                var mouseXY = RG.getMouseXY(e),
                    mouseX  = mouseXY[0],
                    mouseY  = mouseXY[1];
    
                var left   = this.coords[i][0],
                    top    = this.coords[i][1],
                    width  = this.coords[i][2],
                    height = this.coords[i][3];
    
                if (   mouseX >= left
                    && mouseX <= (left + width)
                    && mouseY >= top
                    && mouseY <= top + height) {
                    
                    var tooltip = RG.parseTooltipText(prop['chart.tooltips'], i);
    
                    return {
                        0: this,   object: this,
                        1: left,   x:      left,
                        2: top,    y:      top,
                        3: width,  width:  width,
                        4: height, height: height,
                        5: i,      index:  i,
                                   tooltip: tooltip
                    };
                }
            }
            
            return null;
        };




        /**
        * The Waterfall is slightly different to Bar/Line charts so has this function to get the max value
        */
        this.getMax = function (data)
        {
            var runningTotal = 0, max = 0;
    
            for (var i=0,len=data.length; i<len; i+=1) {
                runningTotal += data[i];
                
                max = ma.max(ma.abs(runningTotal), max);
            }

            return ma.abs(max);
        };




        /**
        * This function facilitates the installation of tooltip event listeners if
        * tooltips are defined.
        */
        this.allowTooltips =
        this.AllowTooltips = function ()
        {
            // Preload any tooltip images that are used in the tooltips
            RG.PreLoadTooltipImages(this);
    
    
            /**
            * This installs the window mousedown event listener that lears any
            * highlight that may be visible.
            */
            RG.InstallWindowMousedownTooltipListener(this);
    
    
            /**
            * This installs the canvas mousemove event listener. This function
            * controls the pointer shape.
            */
            RG.InstallCanvasMousemoveTooltipListener(this);
    
    
            /**
            * This installs the canvas mouseup event listener. This is the
            * function that actually shows the appropriate tooltip (if any).
            */
            RG.InstallCanvasMouseupTooltipListener(this);
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
                RG.Highlight.Rect(this, shape);
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
    
            if (
                   mouseXY[0] > this.gutterLeft
                && mouseXY[0] < (ca.width - this.gutterRight)
                && mouseXY[1] > this.gutterTop
                && mouseXY[1] < (ca.height - this.gutterBottom)
                ) {

                return this;
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
            var coordX     = obj.coords[tooltip.__index__][0];
            var coordY     = obj.coords[tooltip.__index__][1];
            var coordW     = obj.coords[tooltip.__index__][2];
            var coordH     = obj.coords[tooltip.__index__][3];
            var canvasXY   = RG.getCanvasXY(obj.canvas);
            var mouseXY    = RG.getMouseXY(window.event);
            var gutterLeft = obj.gutterLeft;
            var gutterTop  = obj.gutterTop;
            var width      = tooltip.offsetWidth;
            var height     = tooltip.offsetHeight;
            var value      = obj.data[idx];
    
            // Change the value to be the total if necessary
            if (tooltip.__index__ == obj.data.length) {
                value = obj.total;
            }
    
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
        * This method returns the appropriate Y coord for the given value
        * 
        * @param number value The value
        */
        this.getYCoord = function (value)
        {
            if (prop['chart.xaxispos'] == 'center') {
    
                if (value < (-1 * this.max)) {
                    return null;
                }
            
                var coord = (value / this.max) * (this.grapharea / 2);    
                return this.gutterTop + (this.grapharea / 2) - coord;
            
            } else {

                var coord = ( (value - this.scale2.min) / (this.max - this.scale2.min) ) * this.grapharea;
                    coord = coord + this.gutterBottom;

                return ca.height - coord;
            }
        };




        /**
        * This allows for easy specification of gradients
        */
        this.parseColors = function ()
        {
            // Save the original colors so that they can be restored when the canvas is reset
            if (this.original_colors.length === 0) {
                this.original_colors['chart.colors']                = RG.array_clone(prop['chart.colors']);
                this.original_colors['chart.key.colors']            = RG.array_clone(prop['chart.key.colors']);
                this.original_colors['chart.crosshairs.color']      = RG.array_clone(prop['chart.crosshairs.color']);
                this.original_colors['chart.highlight.stroke']      = RG.array_clone(prop['chart.highlight.stroke']);
                this.original_colors['chart.highlight.fill']        = RG.array_clone(prop['chart.highlight.fill']);
                this.original_colors['chart.background.barcolor1']  = RG.array_clone(prop['chart.background.barcolor1']);
                this.original_colors['chart.background.barcolor2']  = RG.array_clone(prop['chart.background.barcolor2']);
                this.original_colors['chart.background.grid.color'] = RG.array_clone(prop['chart.background.grid.color']);
                this.original_colors['chart.strokestyle']           = RG.array_clone(prop['chart.strokestyle']);
                this.original_colors['chart.axis.color']            = RG.array_clone(prop['chart.axis.color']);
            }








            // chart.colors
            var colors = prop['chart.colors'];

            if (colors) {
                for (var i=0,len=colors.length; i<len; ++i) {
                    colors[i] = this.parseSingleColorForGradient(colors[i]);
                }
            }
    
            // chart.key.colors
            var colors = prop['chart.key.colors'];

            if (colors) {
                for (var i=0,len=colors.length; i<len; ++i) {
                    colors[i] = this.parseSingleColorForGradient(colors[i]);
                }
            }
    
             prop['chart.crosshairs.color']      = this.parseSingleColorForGradient(prop['chart.crosshairs.color']);
             prop['chart.highlight.stroke']      = this.parseSingleColorForGradient(prop['chart.highlight.stroke']);
             prop['chart.highlight.fill']        = this.parseSingleColorForGradient(prop['chart.highlight.fill']);
             prop['chart.background.barcolor1']  = this.parseSingleColorForGradient(prop['chart.background.barcolor1']);
             prop['chart.background.barcolor2']  = this.parseSingleColorForGradient(prop['chart.background.barcolor2']);
             prop['chart.background.grid.color'] = this.parseSingleColorForGradient(prop['chart.background.grid.color']);
             prop['chart.strokestyle']           = this.parseSingleColorForGradient(prop['chart.strokestyle']);
             prop['chart.axis.color']            = this.parseSingleColorForGradient(prop['chart.axis.color']);
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
        * 
        * @param string color The color to parse for gradients
        */
        this.parseSingleColorForGradient = function (color)
        {
            if (!color || typeof color != 'string') {
                return color;
            }

            if (typeof color === 'string' && color.match(/^gradient\((.*)\)$/i)) {
                
                var parts = RegExp.$1.split(':');
    
                // Create the gradient

                var grad = co.createLinearGradient(0,ca.height - prop['chart.gutter.bottom'], 0, prop['chart.gutter.top']);
    
                var diff = 1 / (parts.length - 1);
    
                grad.addColorStop(0, RG.trim(parts[0]));
    
                for (var j=1,len=parts.length; j<len; ++j) {
                    grad.addColorStop(j * diff, RG.trim(parts[j]));
                }
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
        * This function runs once only
        * (put at the end of the file (before any effects))
        */
        this.firstDrawFunc = function ()
        {
        };




        /**
        * Waterfall Grow
        * 
        * @param object Options. You can pass frames here - which should be a number
        * @param function An optional function which is called when the animation is finished
        */
        this.grow = function ()
        {
            var opt      = arguments[0] || {};
            var callback = arguments[1] || function () {};
            var frames   = opt.frames || 30;
            var numFrame = 0;
            var obj      = this;
            var data     = RG.array_clone(obj.data);
            
            //Reset The data to zeros
            for (var i=0,len=obj.data.length; i<len; ++i) {
                obj.data[i] /= frames;
            }
            
            /**
            * Fix the scale
            */
            if (obj.Get('chart.ymax') == null) {
                var max   = obj.getMax(data);
                var scale2 = RG.getScale2(obj, {'max':max});
                obj.Set('chart.ymax', scale2.max);
            }

            //obj.Set('chart.multiplier.x', 0);
            //obj.Set('chart.multiplier.w', 0);
    
            function iterator ()
            {
                for (var i=0; i<obj.data.length; ++i) {
                    
                    // This produces a very slight easing effect
                    obj.data[i] = data[i] * RG.Effects.getEasingMultiplier(frames, numFrame);
                }
                
                RGraph.clear(obj.canvas);
                RGraph.redrawCanvas(obj.canvas);
    
                if (++numFrame < frames) {
                    RGraph.Effects.updateCanvas(iterator);
                } else {
                    callback(obj);
                }
            }
            
            iterator();
            
            return this;
        };





        RG.att(ca);


        /**
        * Now, because canvases can support multiple charts, canvases must always be registered
        */
        RG.Register(this);




        /**
        * This is the 'end' of the constructor so if the first argument
        * contains configuration data - handle that.
        */
        if (parseConfObjectForOptions) {
            RG.parseObjectStyleConfig(this, conf.options);
        }




        return this;
    };