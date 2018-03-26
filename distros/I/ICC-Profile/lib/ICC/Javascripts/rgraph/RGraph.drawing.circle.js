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
    RGraph = window.RGraph || {isRGraph: true};
    RGraph.Drawing = RGraph.Drawing || {};

    /**
    * The constructor. This function sets up the object. It takes the ID (the HTML attribute) of the canvas as the
    * first argument and the data as the second. If you need to change this, you can.
    * 
    * @param string id    The canvas tag ID
    * @param number x  The X position of the circle
    * @param number y  The Y position of the circle
    * @param number r  The radius of the circle
    */
    RGraph.Drawing.Circle = function (conf)
    {
        /**
        * Allow for object config style
        */
        if (   typeof conf        === 'object'
            && typeof conf.x      === 'number'
            && typeof conf.y      === 'number'
            && typeof conf.radius === 'number'
            && typeof conf.id     === 'string') {

            var id     = conf.id,
                canvas = document.getElementById(id),
                x      = conf.x,
                y      = conf.y,
                radius = conf.radius,
                parseConfObjectForOptions = true; // Set this so the config is parsed (at the end of the constructor)
        
        } else {
        
            var id     = conf,
                canvas = document.getElementById(id),
                x      = arguments[1],
                y      = arguments[2],
                radius = arguments[3];
        }




        this.id                = id;
        this.canvas            = document.getElementById(this.id);
        this.context           = this.canvas.getContext('2d');
        this.canvas.__object__ = this;
        this.original_colors   = [];
        this.firstDraw         = true; // After the first draw this will be false


        /**
        * Store the properties
        */
        this.centerx = x;
        this.centery = y;
        this.radius  = radius;

        /**
        * This defines the type of this shape
        */
        this.type = 'drawing.circle';


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
        this.canvas.uid = this.canvas.uid ? this.canvas.uid : RGraph.createUID();




        /**
        * Some example background properties
        */
        this.properties =
        {
            'chart.strokestyle':        'rgba(0,0,0,0)',
            'chart.fillstyle':          'red',
            'chart.events.click':       null,
            'chart.events.mousemove':   null,
            'chart.shadow':             false,
            'chart.shadow.color':       'gray',
            'chart.shadow.offsetx':     3,
            'chart.shadow.offsety':     3,
            'chart.shadow.blur':        5,
            'chart.highlight.stroke':   'black',
            'chart.highlight.fill':     'rgba(255,255,255,0.7)',
            'chart.tooltips':           null,
            'chart.tooltips.highlight': true,
            'chart.tooltips.event':     'onclick',
            'chart.linewidth':          2,
            'chart.clearto':   'rgba(0,0,0,0)'
        }

        /**
        * A simple check that the browser has canvas support
        */
        if (!this.canvas) {
            alert('[DRAWING.CIRCLE] No canvas support');
            return;
        }
        
        /**
        * This can be used to store the coordinates of shapes on the graph
        */
        this.coords = [[
            this.centerx,
            this.centery,
            this.radius
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
        * @param name  string The name of the property to set OR it can be a map
        *                     of name/value settings like what you set in the constructor
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
            * This should be done first - prepend the property name with "chart." if necessary
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
        * Draws the circle
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

            pa2(co, 'b lw %',prop['chart.linewidth']);
    
            if (prop['chart.shadow']) {
                RG.setShadow(
                    this,
                    prop['chart.shadow.color'],
                    prop['chart.shadow.offsetx'],
                    prop['chart.shadow.offsety'],
                    prop['chart.shadow.blur']
                );
            }

            pa2(co,
                'b a % % % % % % f % s %',
                this.coords[0][0],
                this.coords[0][1],
                this.radius, 0,
                RG.TWOPI,
                false,
                prop['chart.fillstyle'],
                prop['chart.strokestyle'
            ]);
            
            // Must turn the shadow off before the fill is done
            RG.noShadow(this);
    
    
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
        * Not used by the class during creating the shape, but is used by event handlers
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
    
            if (RG.getHypLength(this.centerx, this.centery, mouseXY[0], mouseXY[1]) <= this.radius) {
                
                return {
                    0: this, 1: this.centerx, 2: this.centery, 3: this.radius, 4: null, 5: 0,
                    'object': this, 'x': this.centerx, 'y': this.centery, 'radius': this.radius, 'index': 0, 'tooltip': prop['chart.tooltips'] ? prop['chart.tooltips'][0] : null
                };
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
            if (prop['chart.tooltips.highlight']) {
                if (typeof prop['chart.highlight.style'] === 'function') {
                    (prop['chart.highlight.style'])(shape);
                } else {
                    //pa2(co, ['b','a',this.centerx, this.centery, this.radius + 0.5, 0, RGraph.TWOPI, false,'f',prop['chart.highlight.fill'],'s',prop['chart.highlight.stroke']]);
                    pa2(co,
                        'b a % % % % % % f % s %',
                        this.centerx,
                        this.centery,
                        this.radius + 0.5,
                        0,
                        RG.TWOPI,
                        false,
                        prop['chart.highlight.fill'],
                        prop['chart.highlight.stroke']
                    );
                }
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
    
                var parts = RegExp.$1.split(':');
    
                // Create the gradient
                var grad = co.createRadialGradient(this.centerx, this.centery, 0, this.centerx, this.centery, this.radius),
                    diff = 1 / (parts.length - 1);

    
                for (var j=0; j<parts.length; j+=1) {
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