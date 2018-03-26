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
    * Having this here means that the RGraph libraries can be included in any order, instead of you having
    * to include the common core library first.
    */

    // Define the RGraph global variable
    RGraph         = window.RGraph || {isRGraph: true};
    RGraph.Drawing = RGraph.Drawing || {};

    /**
    * The constructor. This function sets up the object. It takes the ID (the HTML attribute) of the canvas as the
    * first argument and the data as the second. If you need to change this, you can.
    * 
    * @param string id    The canvas tag ID
    * @param number x  The X position of the rectangle
    * @param number y  The Y position of the rectangle
    * @param number w  The width of the rectangle
    * @param number h  The height of the rectangle
    */
    RGraph.Drawing.Rect = function (conf)
    {
        /**
        * Allow for object config style
        */
        if (   typeof conf        === 'object'
            && typeof conf.x      === 'number'
            && typeof conf.y      === 'number'
            && typeof conf.width  === 'number'
            && typeof conf.height === 'number'
            && typeof conf.id     === 'string') {

            var id     = conf.id,
                x      = conf.x,
                y      = conf.y,
                width  = conf.width,
                height = conf.height,
                parseConfObjectForOptions = true; // Set this so the config is parsed (at the end of the constructor)
        
        } else {

            var id     = conf,
                x      = arguments[1],
                y      = arguments[2],
                width  = arguments[3],
                height = arguments[4];
        }



        // id, x, y, w, h
        this.id                = id;
        this.canvas            = document.getElementById(this.id);
        this.context           = this.canvas.getContext('2d');
        this.colorsParsed      = false;
        this.canvas.__object__ = this;
        this.original_colors   = [];
        this.coordsText        = [];
        this.firstDraw         = true; // After the first draw this will be false

        /**
        * This defines the type of this shape
        */
        this.type = 'drawing.rect';


        /**
        * This facilitates easy object identification, and should always be true
        */
        this.isRGraph = true;


        /**
        * This adds a uid to the object that you can use for identification purposes
        */
        this.uid = RGraph.createUID();


        /**
        * This adds a UID to the canvas for identification purposes
        */
        this.canvas.uid = this.canvas.uid ? this.canvas.uid : RGraph.CreateUID();




        /**
        * Some example background properties
        */
        this.properties =
        {
            'chart.strokestyle':      'rgba(0,0,0,0)',
            'chart.fillstyle':        'red',
            'chart.events.click':     null,
            'chart.events.mousemove': null,
            'chart.shadow':           false,
            'chart.shadow.color':     'gray',
            'chart.shadow.offsetx':   3,
            'chart.shadow.offsety':   3,
            'chart.shadow.blur':      5,
            'chart.highlight.stroke':   'black',
            'chart.highlight.fill':   'rgba(255,255,255,0.7)',
            'chart.tooltips':          null,
            'chart.tooltips.effect':   'fade',
            'chart.tooltips.css.class':'RGraph_tooltip',
            'chart.tooltips.event':    'onclick',
            'chart.tooltips.highlight':true,
            'chart.tooltips.coords.page': false,
            'chart.tooltips.valign':   'top',
            'chart.clearto':   'rgba(0,0,0,0)'
        }

        /**
        * A simple check that the browser has canvas support
        */
        if (!this.canvas) {
            alert('[DRAWING.RECT] No canvas support');
            return;
        }
        
        /**
        * This can be used to store the coordinates of shapes on the graph
        */

        this.coords = [[
            Math.round(x),
            Math.round(y),
            width,
            height
        ]];
        
        /**
        * Create the dollar object so that functions can be added to them
        */
        this.$0 = {};


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
            ma   = Math;
        
        
        
        /**
        * "Decorate" the object with the generic effects if the effects library has been included
        */
        if (RG.Effects && typeof RG.Effects.decorate === 'function') {
            RG.Effects.decorate(this);
        }




        /**
        * A setter method for setting graph properties. It can be used like this: obj.Set('chart.strokestyle', '#666');
        * 
        * @param name  string The name of the property to set
        * @param value mixed  The value of the property
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





    
            prop[name] = value;
    
            return this;
        };




        /**
        * A getter method for retrieving graph properties. It can be used like this: obj.Get('chart.strokestyle');
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
        * Draws the rectangle
        */
        this.draw =
        this.Draw = function ()
        {
            /**
            * Fire the onbeforedraw event
            */
            RG.fireCustomEvent(this, 'onbeforedraw');
    



            /**
            * Stop this growing uncntrollably
            */
            this.coordsText = [];




            /**
            * Parse the colors. This allows for simple gradient syntax
            */
            if (!this.colorsParsed) {
    
                this.parseColors();
    
                // Don't want to do this again
                this.colorsParsed = true;
            }
    
    
            /**
            * Draw the rect here
            */
            pa2(co, ['b']);

            if (prop['chart.shadow']) {
                pa2(co, [
                    'sc',prop['chart.shadow.color'],
                    'sx',prop['chart.shadow.offsetx'],
                    'sy',prop['chart.shadow.offsety'],
                    'sb',prop['chart.shadow.blur'
                ]]);
            }
    
            pa2(co, [
                'r',this.coords[0][0], this.coords[0][1], this.coords[0][2], this.coords[0][3],
                'f',prop['chart.fillstyle'
            ]]);
            
            
            // No shaadow to stroke the rectangle
            RG.NoShadow(this);

            pa2(co, ['s',prop['chart.strokestyle']]);
    
    
            /**
            * This installs the event listeners
            */
            RG.installEventListeners(this);
    

            /**
            * Fire the onfirstdraw event
            */
            if (this.firstDraw) {
                this.firstDraw = false;
                RG.fireCustomEvent(this, 'onfirstdraw');
                this.firstDrawFunc();
            }




            /**
            * Fire the ondraw event
            */
            RG.fireCustomEvent(this, 'ondraw');

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
        * The getObjectByXY() worker method
        */
        this.getObjectByXY = function (e)
        {
            if (this.getShape(e)) {
                return this;
            }
        };




        /**
        * Not used by the class during creating the graph, but is used by event handlers
        * to get the coordinates (if any) of the selected bar
        * 
        * @param object e The event object
        * @param object   OPTIONAL You can pass in the bar object instead of the
        *                          function using "this"
        */
        this.getShape = function (e)
        {
            var mouseXY = RG.getMouseXY(e),
                mouseX  = mouseXY[0],
                mouseY  = mouseXY[1];
    
            for (var i=0,len=this.coords.length; i<len; i++) {
            
                var coords = this.coords[i];

                var left   = coords[0],
                    top    = coords[1],
                    width  = coords[2],
                    height = coords[3];
    
                if (mouseX >= left && mouseX <= (left + width) && mouseY >= top && mouseY <= (top + height)) {
                    
                    return {
                        0: this, 1: left, 2: top, 3: width, 4: height, 5: 0,
                        'object': this, 'x': left, 'y': top, 'width': width, 'height': height, 'index': 0, 'tooltip': prop['chart.tooltips'] ? prop['chart.tooltips'][0] : null
                    };
                }
            }
            
            return null;
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
                RG.Highlight.rect(this, shape);
            }
        };




        /**
        * This allows for easy specification of gradients
        */
        this.parseColors = function ()
        {
            // Save the original colors so that they can be restored when the canvas is reset
            if (this.original_colors.length === 0) {
                this.original_colors['chart.fillstyle']        = RG.array_clone(prop['chart.fillstyle']);
                this.original_colors['chart.strokestyle']      = RG.array_clone(prop['chart.strokestyle']);
                this.original_colors['chart.highlight.stroke'] = RG.array_clone(prop['chart.highlight.stroke']);
                this.original_colors['chart.highlight.fill']   = RG.array_clone(prop['chart.highlight.fill']);
            }




            /**
            * Parse various properties for colors
            */
            prop['chart.fillstyle']        = this.parseSingleColorForGradient(prop['chart.fillstyle']);
            prop['chart.strokestyle']      = this.parseSingleColorForGradient(prop['chart.strokestyle']);
            prop['chart.highlight.stroke'] = this.parseSingleColorForGradient(prop['chart.highlight.stroke']);
            prop['chart.highlight.fill']   = this.parseSingleColorForGradient(prop['chart.highlight.fill']);
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
            if (!color) {
                return color;
            }
    
            if (typeof color === 'string' && color.match(/^gradient\((.*)\)$/i)) {
    
                var parts = RegExp.$1.split(':'),
                    grad = co.createLinearGradient(0,0,ca.width,0),
                    diff = 1 / (parts.length - 1);
    
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
        * Objects are now always registered so that the chart is redrawn if need be.
        */
        RG.register(this);



        /**
        * This is the 'end' of the constructor so if the first argument
        * contains configuration data - handle that.
        */
        if (parseConfObjectForOptions) {
            RG.parseObjectStyleConfig(this, conf.options);
        }
    };